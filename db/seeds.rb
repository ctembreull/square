# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Load sports structure (leagues and conferences) from YAML
if File.exist?(Rails.root.join("db", "seeds", "structure.yml"))
  puts "Seeding sports structure from YAML..."
  Rake::Task["structure:import"].invoke
else
  puts "Warning: db/seeds/structure.yml not found. Run `rake structure:export` to generate it."
end

# Load teams (with colors and styles) from YAML
if File.exist?(Rails.root.join("db", "seeds", "teams.yml"))
  puts "\nSeeding teams from YAML..."
  Rake::Task["seeds:import"].invoke
else
  puts "Warning: db/seeds/teams.yml not found. Run `rake seeds:export` to generate it."
end

puts "\nSeed completed!"
puts "Summary:"
puts "  Leagues:     #{League.count}"
puts "  Conferences: #{Conference.count}"
puts "  Teams:       #{Team.count}"
