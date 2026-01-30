#!/usr/bin/env ruby

require 'bundler/setup'
require 'httparty'
require 'nokogiri'
require 'json'
require 'ostruct'
require 'fileutils'

# /mens-college-basketball/team/_/id/261/vermont-catamounts ->
# "https://site.api.espn.com/apis/site/v2/sports/basketball/mens-college-basketball/teams/44"

SEED_FILE = "./seed.json"
BASE_API_URL = "https://site.api.espn.com/apis/site/v2/sports"


seedfile = File.open(File.expand_path(SEED_FILE, File.dirname(__FILE__)))
seeddata = JSON.load(seedfile, object_class: OpenStruct)

def build_espn_api_url(sport, web_url)
  parts = web_url[1..-1].split('/')
  sport_slug = parts[0]
  team_id    = parts[4]
  team_slug  = parts[5]

  { team: team_slug, url: BASE_API_URL + "/#{sport}/#{sport_slug}/teams/#{team_id}" }
end


seeddata.leagues.each do |league|
  leaguefile = File.open(File.expand_path("./data/#{league.abbr}.json", File.dirname(__FILE__)))
  leaguedata = JSON.load(leaguefile, object_class: OpenStruct)

  next if league.abbr == "nfl"
  sport = leaguedata.sport

  # puts "#{league.abbr}:#{leaguedata.sport}"
  leaguedir = FileUtils.mkdir_p(File.join(File.dirname(leaguefile.path), league.abbr))

  leaguedata.conferences.each do |conf|
    conf.teams.each do |team|
      api_url = build_espn_api_url(sport, team)
      teamfile_path = "./data/#{league.abbr}/#{api_url[:team]}.json"
      next if File.exist?(File.expand_path(teamfile_path, File.dirname(__FILE__)))

      team_url = api_url[:url]

      puts "Fetching #{league.abbr} :: #{team_url}"
      response = HTTParty.get(team_url)
      unless response.success?
        puts "    FAILED: #{response.code}"
        next
      end
      File.open(File.expand_path(teamfile_path, File.dirname(__FILE__)), 'w') do |f|
        f.write JSON.pretty_generate(JSON.parse(response.body))
      end
      sleep(rand(5.0..10.0))
    end
  end
end
