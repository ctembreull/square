namespace :styles do
  desc "Regenerate all team SCSS stylesheets and remove orphans"
  task regenerate_all: :environment do
    puts "Regenerating team stylesheets..."

    count = 0
    Team.includes(:colors, :styles).find_each do |team|
      TeamStylesheetService.generate_for(team)
      count += 1
      print "."
    end

    puts "\nGenerated #{count} team stylesheets in app/assets/stylesheets/teams/"

    # Clean up orphaned stylesheets (files that don't match any team's scss_slug)
    puts "\nCleaning up orphaned stylesheets..."
    # Use the actual scss_slug method to ensure consistency with generation
    valid_slugs = Team.all.map(&:scss_slug).to_set

    teams_dir = Rails.root.join("app/assets/stylesheets/teams")
    orphaned = 0
    Dir.glob(teams_dir.join("_*.scss")).each do |file|
      slug = File.basename(file, ".scss").sub(/^_/, "")
      unless valid_slugs.include?(slug)
        File.delete(file)
        orphaned += 1
        puts "  Deleted orphan: #{File.basename(file)}"
      end
    end

    puts "Removed #{orphaned} orphaned stylesheet#{'s' unless orphaned == 1}." if orphaned > 0
    puts "No orphaned stylesheets found." if orphaned == 0
  end

  desc "Regenerate SCSS stylesheet for a specific team"
  task :regenerate, [:team_id] => :environment do |t, args|
    team = Team.find(args[:team_id])
    TeamStylesheetService.generate_for(team)
    puts "Generated stylesheet for #{team.display_name}: app/assets/stylesheets/teams/_#{team.scss_slug}.scss"
  end
end
