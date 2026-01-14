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
