namespace :styles do
  desc "Regenerate all team SCSS stylesheets"
  task regenerate_all: :environment do
    puts "Regenerating team stylesheets..."

    count = 0
    Team.includes(:colors, :styles).find_each do |team|
      TeamStylesheetService.generate_for(team)
      count += 1
      print "."
    end

    puts "\nGenerated #{count} team stylesheets in app/assets/stylesheets/teams/"
  end

  desc "Regenerate SCSS stylesheet for a specific team"
  task :regenerate, [:team_id] => :environment do |t, args|
    team = Team.find(args[:team_id])
    TeamStylesheetService.generate_for(team)
    puts "Generated stylesheet for #{team.display_name}: app/assets/stylesheets/teams/_#{team.scss_slug}.scss"
  end
end
