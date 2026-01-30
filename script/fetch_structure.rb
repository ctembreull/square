#!/usr/bin/env ruby

require 'bundler/setup'
require 'httparty'
require 'nokogiri'
require 'json'
require 'ostruct'

seedfile = File.open(File.expand_path("./seed.json", File.dirname(__FILE__)))
seeddata = JSON.load(seedfile, object_class: OpenStruct)

seeddata.leagues.each do |league|
  response = HTTParty.get(league.url)
  doc = Nokogiri::HTML(response.body)

  blob = OpenStruct.new({ conferences: [] })

  conferences = doc.css('div.standings__table')
  conferences.each do |conf|
    out = OpenStruct.new({ league: league.abbr, name: "", teams: [] })
    header = conf.css('div.Table__Title').first.text
    out.name = header

    raw_links = conf.css("a").map { |a| a.attributes['href'].value }.uniq
    out.teams = raw_links.reject { |link| link.include? "standing" }

    blob.conferences << out.to_h
  end

  path = "./data/" + league.abbr + ".json"
  File.open(File.expand_path(path, File.dirname(__FILE__)), "w") do |f|
    f.write(JSON.pretty_generate(blob.to_h))
  end
end
