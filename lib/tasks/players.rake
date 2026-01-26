namespace :players do
  desc "Export players to YAML (excludes encrypted emails)"
  task export: :environment do
    output_path = Rails.root.join("db", "seeds", "players.yml")
    FileUtils.mkdir_p(File.dirname(output_path))

    data = {}

    # Export families first (they're referenced by family_id)
    Player.order(:type, :name).each do |player|
      player_key = player.id.to_s

      player_data = {
        "type" => player.type,
        "name" => player.name,
        "display_name" => player.display_name,
        "active" => player.active,
        "chances" => player.chances
      }.compact

      # Store family reference by name (not ID) for portability
      if player.family_id.present?
        family = Player.find_by(id: player.family_id)
        player_data["family_name"] = family&.name
      end

      data[player_key] = player_data
    end

    File.write(output_path, data.to_yaml)
    puts "Exported #{data.keys.count} players to #{output_path}"
    puts "  Families: #{Player.families.count}"
    puts "  Singles: #{Player.singles.count}"
    puts "  Individuals: #{Player.individuals.count}"
    puts "  Charities: #{Player.charities.count}"
    puts "\nNote: Email addresses are NOT exported (encrypted, environment-specific)"
    puts "You'll need to re-enter emails after import."
  end

  desc "Import players from YAML"
  task import: :environment do
    input_path = Rails.root.join("db", "seeds", "players.yml")

    unless File.exist?(input_path)
      puts "Error: #{input_path} not found. Run `rake players:export` first."
      exit 1
    end

    data = YAML.load_file(input_path)
    created = 0
    updated = 0
    family_refs = [] # Store family references to resolve after all players created

    # First pass: create/update all players without family references
    data.each do |old_id, player_data|
      # Find existing player by type + name (unique enough for most cases)
      player = Player.find_by(type: player_data["type"], name: player_data["name"])

      attrs = {
        type: player_data["type"],
        name: player_data["name"],
        display_name: player_data["display_name"],
        active: player_data["active"] || false,
        chances: player_data["chances"] || 0,
        email: "placeholder@example.com" # Placeholder, needs manual update
      }

      if player
        player.update!(attrs.except(:email)) # Don't overwrite existing emails
        updated += 1
      else
        player = Player.create!(attrs)
        created += 1
      end

      # Queue family reference for second pass
      if player_data["family_name"].present?
        family_refs << { player: player, family_name: player_data["family_name"] }
      end

      print "."
    end

    # Second pass: resolve family references
    family_refs.each do |ref|
      family = Player.families.find_by(name: ref[:family_name])
      if family
        ref[:player].update!(family_id: family.id)
      else
        puts "\nWarning: Could not find family '#{ref[:family_name]}' for player '#{ref[:player].name}'"
      end
    end

    puts "\nImport complete:"
    puts "  Players: #{created} created, #{updated} updated"
    puts "  Family references resolved: #{family_refs.count}"
    puts "\nIMPORTANT: Email addresses need to be updated manually!"
    puts "  All imported players have placeholder emails."
  end

  desc "Show current players without writing to file"
  task preview: :environment do
    puts "Current players:"
    puts "  Families: #{Player.families.count}"
    puts "  Singles: #{Player.singles.count}"
    puts "  Individuals: #{Player.individuals.count}"
    puts "  Charities: #{Player.charities.count}"
    puts "  Total: #{Player.count}"
    puts "\nSample (first 5):"

    Player.limit(5).each do |p|
      puts "  #{p.type}: #{p.name} (chances: #{p.chances}, active: #{p.active})"
    end
  end
end
