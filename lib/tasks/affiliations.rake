namespace :affiliations do
  desc "Export affiliations to YAML (using natural keys, not IDs)"
  task export: :environment do
    output_path = Rails.root.join("db", "seeds", "affiliations.yml")
    FileUtils.mkdir_p(File.dirname(output_path))

    data = {}

    # Group affiliations by team for readability
    Affiliation.includes(:team, :league, :conference).each do |affiliation|
      team_key = affiliation.team.scss_slug

      data[team_key] ||= []
      data[team_key] << {
        "league" => affiliation.league.abbr,
        "conference" => affiliation.conference.abbr
      }
    end

    # Sort teams alphabetically, and affiliations within each team by league
    sorted_data = data.sort.to_h
    sorted_data.each do |team_key, affiliations|
      sorted_data[team_key] = affiliations.sort_by { |a| a["league"] }
    end

    File.write(output_path, sorted_data.to_yaml)
    puts "Exported #{Affiliation.count} affiliations for #{data.keys.count} teams to #{output_path}"

    # Summary by league
    League.order(:abbr).each do |league|
      count = Affiliation.where(league_id: league.id).count
      puts "  #{league.abbr}: #{count} teams"
    end
  end

  desc "Import affiliations from YAML"
  task import: :environment do
    input_path = Rails.root.join("db", "seeds", "affiliations.yml")

    unless File.exist?(input_path)
      puts "Error: #{input_path} not found. Run `rake affiliations:export` first."
      exit 1
    end

    data = YAML.load_file(input_path)
    created = 0
    skipped = 0
    errors = []

    # Build lookup hashes for efficient matching
    teams_by_slug = Team.all.index_by(&:scss_slug)
    leagues_by_abbr = League.all.index_by(&:abbr)

    # Build conference lookup: league_abbr + conference_abbr => conference
    conferences_lookup = {}
    Conference.includes(:league).each do |conf|
      key = "#{conf.league.abbr}:#{conf.abbr}"
      conferences_lookup[key] = conf
    end

    data.each do |team_slug, affiliations|
      team = teams_by_slug[team_slug]

      unless team
        errors << "Team not found: #{team_slug}"
        next
      end

      affiliations.each do |aff_data|
        league = leagues_by_abbr[aff_data["league"]]
        unless league
          errors << "League not found: #{aff_data['league']} (for team #{team_slug})"
          next
        end

        conf_key = "#{aff_data['league']}:#{aff_data['conference']}"
        conference = conferences_lookup[conf_key]
        unless conference
          errors << "Conference not found: #{aff_data['conference']} in #{aff_data['league']} (for team #{team_slug})"
          next
        end

        # Check if affiliation already exists
        existing = Affiliation.find_by(team_id: team.id, league_id: league.id, conference_id: conference.id)

        if existing
          skipped += 1
        else
          Affiliation.create!(team: team, league: league, conference: conference)
          created += 1
        end
      end

      print "."
    end

    puts "\nImport complete:"
    puts "  Created: #{created}"
    puts "  Skipped (already exist): #{skipped}"

    if errors.any?
      puts "\nErrors (#{errors.count}):"
      errors.first(10).each { |e| puts "  - #{e}" }
      puts "  ... and #{errors.count - 10} more" if errors.count > 10
    end
  end

  desc "Preview affiliations export without writing to file"
  task preview: :environment do
    puts "Current affiliations by league:"
    League.order(:abbr).each do |league|
      count = Affiliation.where(league_id: league.id).count
      puts "  #{league.abbr}: #{count} teams in #{league.conferences.count} conferences"
    end

    puts "\nSample export (first 3 teams):"

    data = {}
    Affiliation.includes(:team, :league, :conference).limit(10).each do |affiliation|
      team_key = affiliation.team.scss_slug
      data[team_key] ||= []
      data[team_key] << {
        "league" => affiliation.league.abbr,
        "conference" => affiliation.conference.abbr
      }
    end

    puts data.first(3).to_h.to_yaml
  end
end
