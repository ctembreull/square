#!/usr/bin/env ruby

require 'bundler/setup'
require 'httparty'
require 'nokogiri'
require 'json'
require 'ostruct'
require 'fileutils'

require_relative '../config/environment'

def url_to_team_file(url)
  url[1..-1].split('/').last + ".json"
end



matched_count = 0
unmatched_count = 0
show_unmatched = ARGV.delete('--unmatched') || ARGV.delete('-u')

seedfile = File.open(File.expand_path('./seed.json', File.dirname(__FILE__)))
seeddata = JSON.load(seedfile, object_class: OpenStruct)

target_league = ARGV[0]&.downcase
leagues = seeddata.leagues
leagues = leagues.select { |l| l.abbr.downcase == target_league } if target_league

leagues.each do |league_seed|
  league_obj = League.find_by(abbr: league_seed.abbr.upcase)

  leaguefile_path = "./data/#{league_seed.abbr.downcase}.json"
  leaguefile = File.open(File.expand_path(leaguefile_path, File.dirname(__FILE__)))
  leaguedata = JSON.load(leaguefile, object_class: OpenStruct)

  team_lookup = Team.all.index_by(&:generate_espn_slug)

  leaguedata.conferences.each do |conf_seed|
    conf_seed.teams.each do |team_seed|
      teamfile_path = "./data/#{league_seed.abbr.downcase}/" + url_to_team_file(team_seed)
      teamfile = File.open(File.expand_path(teamfile_path, File.dirname(__FILE__)))
      teamdata = JSON.load(teamfile, object_class: OpenStruct)

      if team_lookup[teamdata.team.slug].nil?
        unmatched_count += 1
        puts teamdata.team.slug if show_unmatched
      else
        matched_count += 1
        # puts teamdata.team.slug + " => FOUND"
      end
    end
  end
end

puts "Matched: #{matched_count}"
puts "Unmatched: #{unmatched_count}"
