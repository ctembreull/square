#!/usr/bin/env ruby
# frozen_string_literal: true

# Import ESPN IDs and slugs from cached JSON files into Teams table
#
# Usage:
#   script/import_espn_ids.rb           # Dry run (preview only)
#   script/import_espn_ids.rb --apply   # Actually update the database
#
# Prerequisites:
#   - JSON files in script/data/mbb/*.json, script/data/wbb/*.json, and script/data/nfl/*.json
#   - Teams already exist in database (matched by display_location)

require "bundler/setup"
require_relative "../config/environment"
require "json"

DRY_RUN = !ARGV.include?("--apply")

if DRY_RUN
  puts "=" * 60
  puts "DRY RUN MODE - No changes will be made"
  puts "Run with --apply to update the database"
  puts "=" * 60
  puts
end

DATA_DIR = Rails.root.join("script", "data")

# Step 1: Build unified lookup from MBB (primary source)
puts "Loading MBB data..."
espn_teams = {}

Dir.glob(DATA_DIR.join("mbb", "*.json")).each do |file|
  data = JSON.parse(File.read(file))["team"]
  espn_teams[data["id"]] = {
    espn_id: data["id"].to_i,
    location: data["location"],
    name: data["name"],
    espn_mens_slug: data["slug"],
    espn_womens_slug: nil
  }
end

puts "  Loaded #{espn_teams.size} MBB teams"

# Step 2: Augment with WBB slugs
puts "Loading WBB data..."
wbb_count = 0

Dir.glob(DATA_DIR.join("wbb", "*.json")).each do |file|
  data = JSON.parse(File.read(file))["team"]
  if espn_teams[data["id"]]
    espn_teams[data["id"]][:espn_womens_slug] = data["slug"]
    espn_teams[data["id"]][:womens_name] = data["name"] if data["name"] != espn_teams[data["id"]][:name]
    wbb_count += 1
  else
    puts "  WARNING: WBB team #{data['location']} (ID: #{data['id']}) has no MBB counterpart"
  end
end

puts "  Augmented #{wbb_count} teams with WBB slugs"
puts

# Step 2b: Load NFL data (separate from college)
puts "Loading NFL data..."
nfl_teams = {}

Dir.glob(DATA_DIR.join("nfl", "*.json")).each do |file|
  data = JSON.parse(File.read(file))["team"]
  nfl_teams[data["id"]] = {
    espn_id: data["id"].to_i,
    location: data["location"],
    name: data["name"],
    espn_mens_slug: data["slug"]
  }
end

puts "  Loaded #{nfl_teams.size} NFL teams"
puts

# Normalize location for matching
def normalize_location(loc)
  loc.to_s.strip.downcase
end

# Step 3: Match to existing teams and prepare updates
puts "Matching to existing teams..."
puts

matched = []
unmatched_espn = []
unmatched_db = []

# Build lookup of existing college teams by display_location (our short form)
db_teams_by_display = {}
Team.where(level: "college").each do |team|
  key = normalize_location(team.display_location || team.location)
  db_teams_by_display[key] = team
end

db_teams_used = Set.new

espn_teams.each do |espn_id, espn_data|
  normalized = normalize_location(espn_data[:location])
  team = db_teams_by_display[normalized]

  if team
    db_teams_used << team.id
    matched << {
      team: team,
      espn_id: espn_data[:espn_id],
      espn_mens_slug: espn_data[:espn_mens_slug],
      espn_womens_slug: espn_data[:espn_womens_slug],
      womens_name: espn_data[:womens_name]
    }
  else
    unmatched_espn << espn_data
  end
end

# Find DB college teams with no ESPN match
Team.where(level: "college").each do |team|
  next if db_teams_used.include?(team.id)
  unmatched_db << team
end

# Step 3b: Match NFL teams (by location + name due to shared markets like LA, NY)
puts "Matching NFL teams..."
nfl_matched = []
nfl_unmatched_espn = []
nfl_unmatched_db = []

# Build lookup for pro teams by location + name (handles shared markets)
db_pro_teams_by_key = {}
Team.where(level: "pro").each do |team|
  loc = normalize_location(team.display_location || team.location)
  name = normalize_location(team.name)
  key = "#{loc}|#{name}"
  db_pro_teams_by_key[key] = team
end

pro_teams_used = Set.new

nfl_teams.each do |espn_id, espn_data|
  loc = normalize_location(espn_data[:location])
  name = normalize_location(espn_data[:name])
  key = "#{loc}|#{name}"
  team = db_pro_teams_by_key[key]

  if team
    pro_teams_used << team.id
    nfl_matched << {
      team: team,
      espn_id: espn_data[:espn_id],
      espn_mens_slug: espn_data[:espn_mens_slug]
    }
  else
    nfl_unmatched_espn << espn_data
  end
end

# Find DB pro teams with no ESPN match
Team.where(level: "pro").each do |team|
  next if pro_teams_used.include?(team.id)
  nfl_unmatched_db << team
end

# Combine for unified reporting
matched.concat(nfl_matched)
unmatched_db.concat(nfl_unmatched_db)

# Step 4: Report results
puts "=" * 60
puts "MATCH RESULTS"
puts "=" * 60
puts
puts "College matched: #{matched.size - nfl_matched.size} teams"
puts "NFL matched: #{nfl_matched.size} teams"
puts "Total matched: #{matched.size} teams"
puts
puts "Unmatched ESPN college teams: #{unmatched_espn.size}"
puts "Unmatched ESPN NFL teams: #{nfl_unmatched_espn.size}"
puts "Unmatched DB teams: #{unmatched_db.size}"
puts

if unmatched_espn.any?
  puts "-" * 60
  puts "ESPN TEAMS WITH NO DB MATCH (will be skipped):"
  puts "-" * 60
  unmatched_espn.first(20).each do |data|
    puts "  #{data[:location]} #{data[:name]} (ESPN ID: #{data[:espn_id]})"
  end
  puts "  ... and #{unmatched_espn.size - 20} more" if unmatched_espn.size > 20
  puts
end

if unmatched_db.any?
  puts "-" * 60
  puts "DB TEAMS WITH NO ESPN MATCH (need manual review):"
  puts "-" * 60
  unmatched_db.first(20).each do |team|
    puts "  #{team.location} #{team.name} (DB ID: #{team.id})"
  end
  puts "  ... and #{unmatched_db.size - 20} more" if unmatched_db.size > 20
  puts
end

if matched.any?
  puts "-" * 60
  puts "UPDATES TO APPLY (first 20):"
  puts "-" * 60
  matched.first(20).each do |m|
    team = m[:team]
    changes = []
    changes << "espn_id: #{m[:espn_id]}" if team.espn_id != m[:espn_id]
    changes << "mens_slug: #{m[:espn_mens_slug]}" if team.espn_mens_slug != m[:espn_mens_slug]
    changes << "womens_slug: #{m[:espn_womens_slug]}" if team.espn_womens_slug != m[:espn_womens_slug]
    changes << "womens_name: #{m[:womens_name]}" if m[:womens_name] && team.womens_name.blank?

    if changes.any?
      puts "  #{team.location} #{team.name}"
      changes.each { |c| puts "    + #{c}" }
    end
  end
  puts "  ... and #{matched.size - 20} more" if matched.size > 20
  puts
end

# Step 5: Apply updates if not dry run
if DRY_RUN
  puts "=" * 60
  puts "DRY RUN COMPLETE - No changes made"
  puts "Run with --apply to update #{matched.size} teams"
  puts "=" * 60
else
  puts "=" * 60
  puts "APPLYING UPDATES..."
  puts "=" * 60

  updated = 0
  matched.each do |m|
    team = m[:team]
    attrs = {
      espn_id: m[:espn_id],
      espn_mens_slug: m[:espn_mens_slug],
      espn_womens_slug: m[:espn_womens_slug]
    }
    # Only set womens_name if it's currently blank and ESPN has a different name
    attrs[:womens_name] = m[:womens_name] if m[:womens_name] && team.womens_name.blank?

    if team.update(attrs)
      updated += 1
      print "."
    else
      puts "\n  ERROR updating #{team.location}: #{team.errors.full_messages.join(', ')}"
    end
  end

  puts
  puts
  puts "Updated #{updated} teams"
end
