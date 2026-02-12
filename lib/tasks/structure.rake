namespace :structure do
  desc "Export leagues and conferences to YAML"
  task export: :environment do
    output_path = Rails.root.join("db", "seeds", "structure.yml")
    FileUtils.mkdir_p(File.dirname(output_path))

    data = { "leagues" => {} }
    total_conferences = 0

    League.order(:abbr).each do |league|
      league_key = league.abbr

      league_data = {
        "name" => league.name,
        "sport" => league.sport,
        "gender" => league.gender,
        "level" => league.level,
        "periods" => league.periods,
        "quarters_score_as_halves" => league.quarters_score_as_halves,
        "espn_slug" => league.espn_slug
      }.compact

      # Export conferences nested under league
      if league.conferences.any?
        league_data["conferences"] = []
        league.conferences.order(:abbr).each do |conf|
          league_data["conferences"] << {
            "abbr" => conf.abbr,
            "name" => conf.name,
            "display_name" => conf.display_name
          }.compact
          total_conferences += 1
        end
      end

      data["leagues"][league_key] = league_data
    end

    File.write(output_path, data.to_yaml)
    puts "Exported #{data['leagues'].keys.count} leagues, #{total_conferences} conferences to #{output_path}"
  end

  desc "Import leagues and conferences from YAML"
  task import: :environment do
    input_path = Rails.root.join("db", "seeds", "structure.yml")

    unless File.exist?(input_path)
      puts "Error: #{input_path} not found. Run `rake structure:export` first."
      exit 1
    end

    data = YAML.load_file(input_path)
    created = { leagues: 0, conferences: 0 }
    updated = { leagues: 0, conferences: 0 }

    # First pass: Create/update leagues
    data["leagues"].each do |league_abbr, league_data|
      league = League.find_by(abbr: league_abbr)

      if league
        league.assign_attributes(
          name: league_data["name"],
          sport: league_data["sport"],
          gender: league_data["gender"],
          level: league_data["level"],
          periods: league_data["periods"],
          quarters_score_as_halves: league_data["quarters_score_as_halves"] || false,
          espn_slug: league_data["espn_slug"]
        )
        if league.changed?
          league.save!
          updated[:leagues] += 1
        end
      else
        league = League.create!(
          abbr: league_abbr,
          name: league_data["name"],
          sport: league_data["sport"],
          gender: league_data["gender"],
          level: league_data["level"],
          periods: league_data["periods"],
          quarters_score_as_halves: league_data["quarters_score_as_halves"] || false,
          espn_slug: league_data["espn_slug"]
        )
        created[:leagues] += 1
      end

      # Second pass: Create/update conferences
      if league_data["conferences"]
        league_data["conferences"].each do |conf_data|
          conf = league.conferences.find_by(abbr: conf_data["abbr"])

          if conf
            conf.assign_attributes(
              name: conf_data["name"],
              display_name: conf_data["display_name"]
            )
            if conf.changed?
              conf.save!
              updated[:conferences] += 1
            end
          else
            league.conferences.create!(
              abbr: conf_data["abbr"],
              name: conf_data["name"],
              display_name: conf_data["display_name"]
            )
            created[:conferences] += 1
          end
        end
      end

      print "."
    end

    puts "\nImport complete:"
    puts "  Leagues:     #{created[:leagues]} created, #{updated[:leagues]} updated"
    puts "  Conferences: #{created[:conferences]} created, #{updated[:conferences]} updated"
  end

  desc "Show current structure YAML export without writing to file"
  task preview: :environment do
    data = { "leagues" => {} }
    total_conferences = 0

    League.order(:abbr).limit(2).each do |league|
      league_key = league.abbr

      league_data = {
        "name" => league.name,
        "sport" => league.sport,
        "gender" => league.gender,
        "level" => league.level,
        "periods" => league.periods,
        "quarters_score_as_halves" => league.quarters_score_as_halves,
        "espn_slug" => league.espn_slug
      }.compact

      # Show first 3 conferences as preview
      if league.conferences.any?
        league_data["conferences"] = []
        league.conferences.order(:abbr).limit(3).each do |conf|
          league_data["conferences"] << {
            "abbr" => conf.abbr,
            "name" => conf.name,
            "display_name" => conf.display_name
          }.compact
          total_conferences += 1
        end
      end

      data["leagues"][league_key] = league_data
    end

    puts data.to_yaml
    puts "\n(Showing first 2 leagues with up to 3 conferences each as preview)"
  end
end
