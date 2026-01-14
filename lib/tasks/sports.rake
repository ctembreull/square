namespace :sports do
  desc "Generate db/seeds.rb from current database content"
  task generate_seeds: :environment do
    output = []

    output << "# This file should ensure the existence of records required to run the application in every environment (production,"
    output << "# development, test). The code here should be idempotent so that it can be executed at any point in every environment."
    output << "# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup)."
    output << ""
    output << 'puts "Seeding sports structure..."'
    output << ""
    output << "# " + "=" * 76
    output << "# LEAGUES"
    output << "# " + "=" * 76
    output << ""

    League.order(:id).each do |league|
      var_name = league.abbr.downcase.gsub(/[^a-z0-9]/, '_')
      output << "# #{league.name}"
      output << "#{var_name} = League.find_or_create_by!(abbr: #{league.abbr.inspect}) do |l|"
      output << "  l.name = #{league.name.inspect}"
      output << "  l.sport = #{league.sport.inspect}"
      output << "  l.gender = #{league.gender.inspect}" if league.gender.present?
      output << "  l.level = #{league.level.inspect}" if league.level.present?
      output << "  l.periods = #{league.periods}"
      output << "  l.quarters_score_as_halves = #{league.quarters_score_as_halves}" if league.quarters_score_as_halves
      output << "end"
      output << "puts \"✓ \#{#{var_name}.name}\""
      output << ""
    end

    League.order(:id).each do |league|
      next if league.conferences.empty?

      var_name = league.abbr.downcase.gsub(/[^a-z0-9]/, '_')
      sport_label = case league.sport
      when "basketball"
        league.gender == "men" ? "MBB" : "WBB"
      when "football"
        league.abbr
      else
        league.abbr
      end

      output << "# " + "=" * 76
      output << "# #{league.name.upcase} CONFERENCES"
      output << "# " + "=" * 76
      output << ""
      output << "#{var_name}_conferences = ["

      league.conferences.order(:abbr).each do |conf|
        output << "  { name: #{conf.name.inspect}, display_name: #{conf.display_name.inspect}, abbr: #{conf.abbr.inspect} },"
      end

      output << "]"
      output << ""
      output << "#{var_name}_conferences.each do |conf_data|"
      output << "  conf = #{var_name}.conferences.find_or_create_by!(abbr: conf_data[:abbr]) do |c|"
      output << "    c.name = conf_data[:name]"
      output << "    c.display_name = conf_data[:display_name]"
      output << "  end"
      output << "  puts \"  ✓ \#{conf.display_name} (#{sport_label})\""
      output << "end"
      output << ""
    end

    if Team.any?
      output << "# " + "=" * 76
      output << "# TEAMS"
      output << "# " + "=" * 76
      output << ""

      Team.order(:location, :name).each do |team|
        var_name = team.location.downcase.gsub(/[^a-z0-9]/, '_')
        output << "# #{team.display_name}"
        output << "#{var_name} = Team.find_or_create_by!(location: #{team.location.inspect}, name: #{team.name.inspect}) do |t|"
        output << "  t.abbr = #{team.abbr.inspect}" if team.abbr.present?
        output << "  t.display_location = #{team.display_location.inspect}" if team.display_location.present?
        output << "  t.womens_name = #{team.womens_name.inspect}" if team.womens_name.present?
        output << "  t.level = #{team.level.inspect}" if team.level.present?
        output << "  t.brand_info = #{team.brand_info.inspect}" if team.brand_info.present?
        output << "end"
        output << "puts \"  ✓ \#{#{var_name}.display_name}\""
        output << ""
      end
    end

    output << 'puts "\nSeed completed!"'
    output << 'puts "Summary:"'
    output << 'puts "  Leagues: #{League.count}"'
    output << 'puts "  Conferences: #{Conference.count}"'
    output << 'puts "  Divisions: #{Division.count}"'
    output << 'puts "  Teams: #{Team.count}"'

    File.write("db/seeds.rb", output.join("\n") + "\n")
    puts "✓ Generated db/seeds.rb from current database"
    puts "  Leagues: #{League.count}"
    puts "  Conferences: #{Conference.count}"
    puts "  Teams: #{Team.count}"
  end
end
