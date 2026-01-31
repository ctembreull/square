#!/usr/bin/env ruby

require 'bundler/setup'
require 'httparty'
require 'nokogiri'
require 'json'
require 'ostruct'
require 'fileutils'

require_relative '../config/environment'

seedfile = File.open(File.expand_path('./seed.json', File.dirname(__FILE__)))
seeddata = JSON.load(seedfile, object_class: OpenStruct)

seeddata.leagues.each do |league_seed|
  league_obj = League.find_by(abbr: league_seed.abbr.upcase)

  leaguefile_path = "./data/#{league_seed.abbr.downcase}.json"
  leaguefile = File.open(File.expand_path(leaguefile_path, File.dirname(__FILE__)))
  leaguedata = JSON.load(leaguefile, object_class: OpenStruct)

  leaguedata.conferences.each do |conf_seed|
    conf_obj = league_obj.conferences.find_by(name: conf_seed.name)

    puts "#{league_seed.abbr} :: #{conf_seed.name} => #{conf_obj.nil? ? "Not Found" : "Found"}"
    puts "\n"
  end
end
