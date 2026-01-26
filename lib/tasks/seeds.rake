namespace :seeds do
  desc "Export teams with colors and styles to YAML"
  task export: :environment do
    output_path = Rails.root.join("db", "seeds", "teams.yml")
    FileUtils.mkdir_p(File.dirname(output_path))

    data = {}

    Team.includes(:colors, :styles).alphabetical.each do |team|
      team_key = team.scss_slug

      team_data = {
        "abbr" => team.abbr,
        "location" => team.location,
        "display_location" => team.display_location,
        "name" => team.name,
        "level" => team.level
      }.compact

      # Export colors keyed by slug (name-based, unique within team)
      if team.colors.any?
        team_data["colors"] = {}
        team.colors.ordered.each do |color|
          color_slug = color.name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/-+$/, "")
          team_data["colors"][color_slug] = {
            "name" => color.name,
            "hex" => color.hex,
            "primary" => color.primary
          }.compact
        end
      end

      # Export styles keyed by slug (name-based, unique within team)
      if team.styles.any?
        team_data["styles"] = {}
        team.styles.ordered.each do |style|
          team_data["styles"][style.scss_slug] = {
            "name" => style.name,
            "css" => style.css,
            "default" => style.default
          }.compact
        end
      end

      data[team_key] = team_data
    end

    File.write(output_path, data.to_yaml)
    puts "Exported #{data.keys.count} teams to #{output_path}"
  end

  desc "Import teams with colors and styles from YAML"
  task import: :environment do
    input_path = Rails.root.join("db", "seeds", "teams.yml")

    unless File.exist?(input_path)
      puts "Error: #{input_path} not found. Run `rake seeds:export` first."
      exit 1
    end

    data = YAML.load_file(input_path)
    created = { teams: 0, colors: 0, styles: 0 }
    updated = { teams: 0, colors: 0, styles: 0 }

    data.each do |team_slug, team_data|
      # Find existing team by scss_slug or create new
      team = Team.all.find { |t| t.scss_slug == team_slug }

      if team
        team.update!(
          abbr: team_data["abbr"],
          location: team_data["location"],
          display_location: team_data["display_location"],
          name: team_data["name"],
          level: team_data["level"]
        )
        updated[:teams] += 1
      else
        team = Team.create!(
          abbr: team_data["abbr"],
          location: team_data["location"],
          display_location: team_data["display_location"],
          name: team_data["name"],
          level: team_data["level"]
        )
        created[:teams] += 1
      end

      # Import colors
      if team_data["colors"]
        team_data["colors"].each do |color_slug, color_data|
          existing_color = team.colors.find { |c| c.name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/-+$/, "") == color_slug }

          if existing_color
            existing_color.update!(
              name: color_data["name"],
              hex: color_data["hex"],
              primary: color_data["primary"] || false
            )
            updated[:colors] += 1
          else
            team.colors.create!(
              name: color_data["name"],
              hex: color_data["hex"],
              primary: color_data["primary"] || false
            )
            created[:colors] += 1
          end
        end
      end

      # Import styles
      if team_data["styles"]
        team_data["styles"].each do |style_slug, style_data|
          existing_style = team.styles.find { |s| s.scss_slug == style_slug }

          if existing_style
            existing_style.update!(
              name: style_data["name"],
              css: style_data["css"],
              default: style_data["default"] || false
            )
            updated[:styles] += 1
          else
            team.styles.create!(
              name: style_data["name"],
              css: style_data["css"],
              default: style_data["default"] || false
            )
            created[:styles] += 1
          end
        end
      end

      print "."
    end

    puts "\nImport complete:"
    puts "  Teams:  #{created[:teams]} created, #{updated[:teams]} updated"
    puts "  Colors: #{created[:colors]} created, #{updated[:colors]} updated"
    puts "  Styles: #{created[:styles]} created, #{updated[:styles]} updated"
  end

  desc "Export current Leagues and Conferences to db/seeds.rb"
  task export_structure: :environment do
    output = []

    output << "# This file should ensure the existence of records required to run the application in every environment (production,"
    output << "# development, test). The code here should be idempotent so that it can be executed at any point in every environment."
    output << "# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup)."
    output << "#"
    output << "# Generated from database on #{Time.current.strftime('%Y-%m-%d %H:%M')}"
    output << ""
    output << 'puts "Seeding sports structure..."'
    output << ""
    output << "# ============================================================================"
    output << "# LEAGUES"
    output << "# ============================================================================"
    output << ""

    # Export leagues
    League.order(:id).each do |l|
      var_name = l.abbr.downcase
      output << "# #{l.name}"
      output << "#{var_name} = League.find_or_create_by!(abbr: #{l.abbr.inspect}) do |l|"
      output << "  l.name = #{l.name.inspect}"
      output << "  l.sport = #{l.sport.inspect}"
      output << "  l.gender = #{l.gender.inspect}"
      output << "  l.level = #{l.level.inspect}"
      output << "  l.periods = #{l.periods}"
      output << "  l.quarters_score_as_halves = true" if l.quarters_score_as_halves
      output << "end"
      output << "puts \"✓ \#{#{var_name}.name}\""
      output << ""
    end

    # Export conferences grouped by league
    League.order(:id).each do |league|
      conferences = league.conferences.order(:name)
      next if conferences.empty?

      var_name = league.abbr.downcase
      output << "# ============================================================================"
      output << "# #{league.name.upcase} CONFERENCES"
      output << "# ============================================================================"
      output << ""
      output << "#{var_name}_conferences = ["

      conferences.each_with_index do |c, idx|
        comma = idx < conferences.length - 1 ? "," : ""
        output << "  { abbr: #{c.abbr.inspect}, name: #{c.name.inspect}, display_name: #{c.display_name.inspect} }#{comma}"
      end

      output << "]"
      output << ""
      output << "#{var_name}_conferences.each do |conf_data|"
      output << "  conf = #{var_name}.conferences.find_or_create_by!(abbr: conf_data[:abbr]) do |c|"
      output << "    c.name = conf_data[:name]"
      output << "    c.display_name = conf_data[:display_name]"
      output << "  end"
      output << "  puts \"  ✓ \#{conf.display_name} (#{league.abbr})\""
      output << "end"
      output << ""
    end

    output << "# ============================================================================"
    output << "# TEAMS - Use `rake seeds:import` to import from db/seeds/teams.yml"
    output << "# ============================================================================"
    output << "# Teams are NOT seeded here to avoid conflicts with the YAML import."
    output << "# The YAML file is the single source of truth for team data."
    output << ""
    output << 'puts "\nSeed completed!"'
    output << 'puts "Summary:"'
    output << 'puts "  Leagues: #{League.count}"'
    output << 'puts "  Conferences: #{Conference.count}"'
    output << 'puts "  Teams: #{Team.count} (run `rake seeds:import` to import from YAML)"'

    File.write(Rails.root.join("db", "seeds.rb"), output.join("\n") + "\n")

    puts "Exported to db/seeds.rb:"
    puts "  Leagues: #{League.count}"
    puts "  Conferences: #{Conference.count}"
  end

  desc "Show current teams YAML export without writing to file"
  task preview: :environment do
    data = {}

    Team.includes(:colors, :styles).alphabetical.limit(5).each do |team|
      team_key = team.scss_slug

      team_data = {
        "abbr" => team.abbr,
        "location" => team.location,
        "display_location" => team.display_location,
        "name" => team.name,
        "level" => team.level
      }.compact

      if team.colors.any?
        team_data["colors"] = {}
        team.colors.ordered.each do |color|
          color_slug = color.name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/-+$/, "")
          team_data["colors"][color_slug] = {
            "name" => color.name,
            "hex" => color.hex,
            "primary" => color.primary
          }.compact
        end
      end

      if team.styles.any?
        team_data["styles"] = {}
        team.styles.ordered.each do |style|
          team_data["styles"][style.scss_slug] = {
            "name" => style.name,
            "css" => style.css,
            "default" => style.default
          }.compact
        end
      end

      data[team_key] = team_data
    end

    puts data.to_yaml
    puts "\n(Showing first 5 teams as preview)"
  end
end
