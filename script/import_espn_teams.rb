#!/usr/bin/env ruby
# frozen_string_literal: true

# Import missing teams from ESPN data and create affiliations
#
# Usage:
#   script/import_espn_teams.rb           # Dry run (preview only)
#   script/import_espn_teams.rb --apply   # Actually update the database
#
# Prerequisites:
#   - Team JSON files in script/data/{mbb,wbb,fbs,fcs}/*.json
#   - Standings files: script/data/{mbb,wbb,fbs,fcs}.json
#   - Conferences already exist in database (matched by name)
#
# This script:
#   1. Creates skeleton Team records for ESPN teams not in DB
#   2. Creates MBB, WBB, FBS, and FCS affiliations based on standings data

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

# Step 1: Load all ESPN team data from cached JSON files
puts "Loading ESPN team data..."

espn_teams = {}

Dir.glob(DATA_DIR.join("mbb", "*.json")).each do |file|
  data = JSON.parse(File.read(file))["team"]
  espn_teams[data["id"].to_i] = {
    espn_id: data["id"].to_i,
    location: data["location"],
    name: data["name"],
    abbr: data["abbreviation"],
    espn_mens_slug: data["slug"],
    espn_womens_slug: nil,
    womens_name: nil
  }
end

puts "  Loaded #{espn_teams.size} MBB teams"

# Augment with WBB data
wbb_count = 0
Dir.glob(DATA_DIR.join("wbb", "*.json")).each do |file|
  data = JSON.parse(File.read(file))["team"]
  espn_id = data["id"].to_i
  if espn_teams[espn_id]
    espn_teams[espn_id][:espn_womens_slug] = data["slug"]
    espn_teams[espn_id][:womens_name] = data["name"] if data["name"] != espn_teams[espn_id][:name]
    wbb_count += 1
  end
end

puts "  Augmented #{wbb_count} teams with WBB data"
puts

# Step 2: Find teams that don't exist in DB
puts "Finding teams to create..."

# Only check college teams - ESPN IDs can overlap between college and pro
existing_espn_ids = Team.where(level: "college").where.not(espn_id: nil).pluck(:espn_id).to_set
teams_to_create = espn_teams.values.reject { |t| existing_espn_ids.include?(t[:espn_id]) }

puts "  #{teams_to_create.size} teams need to be created"
puts

# Step 3: Load standings data for affiliations
puts "Loading standings data..."

def extract_espn_id(link)
  # /mens-college-basketball/team/_/id/261/vermont-catamounts -> 261
  match = link.match(%r{/id/(\d+)/})
  match ? match[1].to_i : nil
end

mbb_standings = JSON.parse(File.read(DATA_DIR.join("mbb.json")))
wbb_standings = JSON.parse(File.read(DATA_DIR.join("wbb.json")))
fbs_standings = JSON.parse(File.read(DATA_DIR.join("fbs.json")))
fcs_standings = JSON.parse(File.read(DATA_DIR.join("fcs.json")))

puts "  MBB: #{mbb_standings['conferences'].size} conferences"
puts "  WBB: #{wbb_standings['conferences'].size} conferences"
puts "  FBS: #{fbs_standings['conferences'].size} conferences"
puts "  FCS: #{fcs_standings['conferences'].size} conferences"
puts

# Step 4: Build affiliation plan
puts "Planning affiliations..."

mbb_league = League.find_by!(abbr: "MBB")
wbb_league = League.find_by!(abbr: "WBB")
fbs_league = League.find_by!(abbr: "FBS")
fcs_league = League.find_by!(abbr: "FCS")

mbb_affiliations = []
wbb_affiliations = []
fbs_affiliations = []
fcs_affiliations = []

mbb_standings["conferences"].each do |conf_data|
  conference = mbb_league.conferences.find_by(name: conf_data["name"])
  unless conference
    puts "  WARNING: MBB conference not found: #{conf_data['name']}"
    next
  end

  conf_data["teams"].each do |link|
    espn_id = extract_espn_id(link)
    next unless espn_id
    mbb_affiliations << { espn_id: espn_id, conference: conference }
  end
end

wbb_standings["conferences"].each do |conf_data|
  conference = wbb_league.conferences.find_by(name: conf_data["name"])
  unless conference
    puts "  WARNING: WBB conference not found: #{conf_data['name']}"
    next
  end

  conf_data["teams"].each do |link|
    espn_id = extract_espn_id(link)
    next unless espn_id
    wbb_affiliations << { espn_id: espn_id, conference: conference }
  end
end

fbs_standings["conferences"].each do |conf_data|
  conference = fbs_league.conferences.find_by(name: conf_data["name"])
  unless conference
    puts "  WARNING: FBS conference not found: #{conf_data['name']}"
    next
  end

  conf_data["teams"].each do |link|
    espn_id = extract_espn_id(link)
    next unless espn_id
    fbs_affiliations << { espn_id: espn_id, conference: conference }
  end
end

fcs_standings["conferences"].each do |conf_data|
  conference = fcs_league.conferences.find_by(name: conf_data["name"])
  unless conference
    puts "  WARNING: FCS conference not found: #{conf_data['name']}"
    next
  end

  conf_data["teams"].each do |link|
    espn_id = extract_espn_id(link)
    next unless espn_id
    fcs_affiliations << { espn_id: espn_id, conference: conference }
  end
end

puts "  MBB affiliations to create: #{mbb_affiliations.size}"
puts "  WBB affiliations to create: #{wbb_affiliations.size}"
puts "  FBS affiliations to create: #{fbs_affiliations.size}"
puts "  FCS affiliations to create: #{fcs_affiliations.size}"
puts

# Step 5: Report
puts "=" * 60
puts "SUMMARY"
puts "=" * 60
puts
puts "Teams to create: #{teams_to_create.size}"
puts "MBB affiliations: #{mbb_affiliations.size}"
puts "WBB affiliations: #{wbb_affiliations.size}"
puts "FBS affiliations: #{fbs_affiliations.size}"
puts "FCS affiliations: #{fcs_affiliations.size}"
puts

if teams_to_create.any?
  puts "-" * 60
  puts "TEAMS TO CREATE (first 20):"
  puts "-" * 60
  teams_to_create.first(20).each do |t|
    womens = t[:womens_name] ? " (W: #{t[:womens_name]})" : ""
    puts "  #{t[:location]} #{t[:name]}#{womens} [#{t[:abbr]}]"
  end
  puts "  ... and #{teams_to_create.size - 20} more" if teams_to_create.size > 20
  puts
end

# Step 6: Apply if not dry run
if DRY_RUN
  puts "=" * 60
  puts "DRY RUN COMPLETE - No changes made"
  puts "Run with --apply to create #{teams_to_create.size} teams and affiliations"
  puts "=" * 60
else
  puts "=" * 60
  puts "APPLYING CHANGES..."
  puts "=" * 60

  # Create teams
  created_teams = 0
  teams_to_create.each do |t|
    Team.create!(
      display_location: t[:location],
      location: t[:location],  # Same as display for ESPN-sourced teams
      name: t[:name],
      abbr: t[:abbr],
      level: "college",
      womens_name: t[:womens_name],
      espn_id: t[:espn_id],
      espn_mens_slug: t[:espn_mens_slug],
      espn_womens_slug: t[:espn_womens_slug]
    )
    created_teams += 1
    print "."
  end
  puts
  puts "Created #{created_teams} teams"
  puts

  # Build team lookup by ESPN ID (college only - ESPN IDs overlap with NFL)
  teams_by_espn_id = Team.where(level: "college").where.not(espn_id: nil).index_by(&:espn_id)

  # Create MBB affiliations
  puts "Creating MBB affiliations..."
  mbb_created = 0
  mbb_skipped = 0
  mbb_affiliations.each do |aff|
    team = teams_by_espn_id[aff[:espn_id]]
    unless team
      puts "  WARNING: No team found for ESPN ID #{aff[:espn_id]}"
      next
    end

    existing = Affiliation.find_by(team: team, conference: aff[:conference])
    if existing
      mbb_skipped += 1
    else
      Affiliation.create!(team: team, conference: aff[:conference], league: aff[:conference].league)
      mbb_created += 1
    end
  end
  puts "  Created: #{mbb_created}, Skipped (existing): #{mbb_skipped}"

  # Create WBB affiliations
  puts "Creating WBB affiliations..."
  wbb_created = 0
  wbb_skipped = 0
  wbb_affiliations.each do |aff|
    team = teams_by_espn_id[aff[:espn_id]]
    unless team
      puts "  WARNING: No team found for ESPN ID #{aff[:espn_id]}"
      next
    end

    existing = Affiliation.find_by(team: team, conference: aff[:conference])
    if existing
      wbb_skipped += 1
    else
      Affiliation.create!(team: team, conference: aff[:conference], league: aff[:conference].league)
      wbb_created += 1
    end
  end
  puts "  Created: #{wbb_created}, Skipped (existing): #{wbb_skipped}"

  # Create FBS affiliations
  puts "Creating FBS affiliations..."
  fbs_created = 0
  fbs_skipped = 0
  fbs_affiliations.each do |aff|
    team = teams_by_espn_id[aff[:espn_id]]
    unless team
      puts "  WARNING: No team found for ESPN ID #{aff[:espn_id]}"
      next
    end

    existing = Affiliation.find_by(team: team, conference: aff[:conference])
    if existing
      fbs_skipped += 1
    else
      Affiliation.create!(team: team, conference: aff[:conference], league: aff[:conference].league)
      fbs_created += 1
    end
  end
  puts "  Created: #{fbs_created}, Skipped (existing): #{fbs_skipped}"

  # Create FCS affiliations
  puts "Creating FCS affiliations..."
  fcs_created = 0
  fcs_skipped = 0
  fcs_affiliations.each do |aff|
    team = teams_by_espn_id[aff[:espn_id]]
    unless team
      puts "  WARNING: No team found for ESPN ID #{aff[:espn_id]}"
      next
    end

    existing = Affiliation.find_by(team: team, conference: aff[:conference])
    if existing
      fcs_skipped += 1
    else
      Affiliation.create!(team: team, conference: aff[:conference], league: aff[:conference].league)
      fcs_created += 1
    end
  end
  puts "  Created: #{fcs_created}, Skipped (existing): #{fcs_skipped}"

  puts
  puts "=" * 60
  puts "COMPLETE"
  puts "  Teams: #{created_teams} created"
  puts "  MBB affiliations: #{mbb_created} created, #{mbb_skipped} existed"
  puts "  WBB affiliations: #{wbb_created} created, #{wbb_skipped} existed"
  puts "  FBS affiliations: #{fbs_created} created, #{fbs_skipped} existed"
  puts "  FCS affiliations: #{fcs_created} created, #{fcs_skipped} existed"
  puts "=" * 60
end
