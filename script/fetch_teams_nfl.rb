#!/usr/bin/env ruby

require 'bundler/setup'
require 'httparty'
require 'nokogiri'
require 'json'
require 'ostruct'
require 'fileutils'

ESPN_NFL_URL = "https://site.api.espn.com/apis/site/v2/sports/football/nfl/teams"

response = HTTParty.get(ESPN_NFL_URL)
nfl = JSON.parse(response.body)
teams = nfl["sports"].first["leagues"].first["teams"]

teams.each do |team|
  teamfile_path = "./data/nfl/#{team['team']['slug']}.json"
  puts teamfile_path
  next if File.exist?(File.expand_path(teamfile_path, File.dirname(__FILE__)))

  teamfile = File.open(File.expand_path(teamfile_path, File.dirname(__FILE__)), 'w') do |f|
    f.write JSON.pretty_generate(team)
  end
end
