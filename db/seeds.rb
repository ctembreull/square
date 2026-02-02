# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Generated from database on 2026-02-02 20:15

puts "Seeding sports structure..."

# ============================================================================
# LEAGUES
# ============================================================================

# NCAA Men's Division I Basketball
mbb = League.find_or_create_by!(abbr: "MBB") do |l|
  l.name = "NCAA Men's Division I Basketball"
  l.sport = "basketball"
  l.gender = "men"
  l.level = "college"
  l.periods = 2
  l.espn_slug = "basketball/mens-college-basketball"
end
puts "✓ #{mbb.name}"

# NCAA Women's Division I Basketball
wbb = League.find_or_create_by!(abbr: "WBB") do |l|
  l.name = "NCAA Women's Division I Basketball"
  l.sport = "basketball"
  l.gender = "women"
  l.level = "college"
  l.periods = 4
  l.quarters_score_as_halves = true
  l.espn_slug = "basketball/womens-college-basketball"
end
puts "✓ #{wbb.name}"

# National Football League
nfl = League.find_or_create_by!(abbr: "NFL") do |l|
  l.name = "National Football League"
  l.sport = "football"
  l.gender = "men"
  l.level = "pro"
  l.periods = 4
  l.espn_slug = "football/nfl"
end
puts "✓ #{nfl.name}"

# NCAA Football Bowl Subdivision
fbs = League.find_or_create_by!(abbr: "FBS") do |l|
  l.name = "NCAA Football Bowl Subdivision"
  l.sport = "football"
  l.gender = "men"
  l.level = "college"
  l.periods = 4
  l.espn_slug = "football/college-football"
end
puts "✓ #{fbs.name}"

# NCAA Football Championship Subdivision
fcs = League.find_or_create_by!(abbr: "FCS") do |l|
  l.name = "NCAA Football Championship Subdivision"
  l.sport = "football"
  l.gender = "men"
  l.level = "college"
  l.periods = 4
end
puts "✓ #{fcs.name}"

# ============================================================================
# NCAA MEN'S DIVISION I BASKETBALL CONFERENCES
# ============================================================================

mbb_conferences = [
  { abbr: "AEAST", name: "America East Conference", display_name: " America East" },
  { abbr: "AAC", name: "American Conference", display_name: "American" },
  { abbr: "A10", name: "Atlantic 10 Conference", display_name: "Atlantic 10" },
  { abbr: "ACC", name: "Atlantic Coast Conference", display_name: "Atlantic Coast" },
  { abbr: "ASUN", name: "Atlantic Sun Conference", display_name: "Atlantic Sun" },
  { abbr: "B12", name: "Big 12 Conference", display_name: "Big 12" },
  { abbr: "BIGEAST", name: "Big East Conference", display_name: "Big East" },
  { abbr: "SKY", name: "Big Sky Conference", display_name: "Big Sky" },
  { abbr: "BSOUTH", name: "Big South Conference", display_name: "Big South" },
  { abbr: "B1G", name: "Big Ten Conference", display_name: "Big Ten" },
  { abbr: "BWEST", name: "Big West Conference", display_name: "Big West" },
  { abbr: "CAA", name: "Coastal Athletic Association", display_name: "Coastal " },
  { abbr: "CUSA", name: "Conference USA", display_name: " Conference USA" },
  { abbr: "HORIZ", name: "Horizon League", display_name: " Horizon League" },
  { abbr: "IVY", name: "Ivy League", display_name: " Ivy League" },
  { abbr: "METRO", name: "Metro Atlantic Athletic Conference", display_name: "Metro Atlantic" },
  { abbr: "MAC", name: "Mid-American Conference", display_name: "Mid-American" },
  { abbr: "MEAC", name: "Mid-Eastern Athletic Conference", display_name: "Mid-Eastern" },
  { abbr: "MVC", name: "Missouri Valley Conference", display_name: "Missouri Valley" },
  { abbr: "MWC", name: "Mountain West Conference", display_name: "Mountain West" },
  { abbr: "NEC", name: "Northeast Conference", display_name: "Northeast" },
  { abbr: "OVC", name: "Ohio Valley Conference", display_name: "Ohio Valley" },
  { abbr: "PAT", name: "Patriot League", display_name: "Patriot League" },
  { abbr: "SEC", name: "Southeastern Conference", display_name: "Southeastern" },
  { abbr: "SOU", name: "Southern Conference", display_name: "Southern" },
  { abbr: "SLND", name: "Southland Conference", display_name: "Southland" },
  { abbr: "SWAC", name: "Southwestern Athletic Conference", display_name: "Southwestern" },
  { abbr: "SUM", name: "Summit League", display_name: "Summit" },
  { abbr: "SUN", name: "Sun Belt Conference", display_name: "Sun Belt" },
  { abbr: "WCC", name: "West Coast Conference", display_name: "West Coast" },
  { abbr: "WEST", name: "Western Athletic Conference", display_name: "Western" }
]

mbb_conferences.each do |conf_data|
  conf = mbb.conferences.find_or_create_by!(abbr: conf_data[:abbr]) do |c|
    c.name = conf_data[:name]
    c.display_name = conf_data[:display_name]
  end
  puts "  ✓ #{conf.display_name} (MBB)"
end

# ============================================================================
# NCAA WOMEN'S DIVISION I BASKETBALL CONFERENCES
# ============================================================================

wbb_conferences = [
  { abbr: "AEAST", name: "America East Conference", display_name: "America East" },
  { abbr: "AAC", name: "American Conference", display_name: "American" },
  { abbr: "A10", name: "Atlantic 10 Conference", display_name: "Atlantic 10" },
  { abbr: "ACC", name: "Atlantic Coast Conference", display_name: "Atlantic Coast" },
  { abbr: "ASUN", name: "Atlantic Sun Conference", display_name: "Atlantic Sun" },
  { abbr: "B12", name: "Big 12 Conference", display_name: "Big 12" },
  { abbr: "BIGEAST", name: "Big East Conference", display_name: "Big East" },
  { abbr: "BSKY", name: "Big Sky Conference", display_name: "Big Sky" },
  { abbr: "BSOUTH", name: "Big South Conference", display_name: "Big South" },
  { abbr: "B1G", name: "Big Ten Conference", display_name: "Big Ten" },
  { abbr: "BWEST", name: "Big West Conference", display_name: "Big West" },
  { abbr: "CAA", name: "Coastal Athletic Association", display_name: "Coastal" },
  { abbr: "CUSA", name: "Conference USA", display_name: "Conference USA" },
  { abbr: "HORIZ", name: "Horizon League", display_name: "Horizon League" },
  { abbr: "IVY", name: "Ivy League", display_name: "Ivy League" },
  { abbr: "METRO", name: "Metro Atlantic Athletic Conference", display_name: "Metro Atlantic" },
  { abbr: "MAC", name: "Mid-American Conference", display_name: "Mid-American" },
  { abbr: "MEAC", name: "Mid-Eastern Athletic Conference", display_name: "Mid-Eastern" },
  { abbr: "MVC", name: "Missouri Valley Conference", display_name: "Missouri Valley" },
  { abbr: "MWC", name: "Mountain West Conference", display_name: "Mountain West" },
  { abbr: "NEC", name: "Northeast Conference", display_name: "Northeast" },
  { abbr: "OVC", name: "Ohio Valley Conference", display_name: "Ohio Valley" },
  { abbr: "PAT", name: "Patriot League", display_name: "Patriot League" },
  { abbr: "SEC", name: "Southeastern Conference", display_name: "Southeastern" },
  { abbr: "SOU", name: "Southern Conference", display_name: "Southern" },
  { abbr: "SLND", name: "Southland Conference", display_name: "Southland" },
  { abbr: "SWAC", name: "Southwestern Athletic Conference", display_name: "Southwestern" },
  { abbr: "SUM", name: "Summit League", display_name: "Summit League" },
  { abbr: "SUN", name: "Sun Belt Conference", display_name: "Sun Belt" },
  { abbr: "WCC", name: "West Coast Conference", display_name: "West Coast" },
  { abbr: "WEST", name: "Western Athletic Conference", display_name: "Western" }
]

wbb_conferences.each do |conf_data|
  conf = wbb.conferences.find_or_create_by!(abbr: conf_data[:abbr]) do |c|
    c.name = conf_data[:name]
    c.display_name = conf_data[:display_name]
  end
  puts "  ✓ #{conf.display_name} (WBB)"
end

# ============================================================================
# NATIONAL FOOTBALL LEAGUE CONFERENCES
# ============================================================================

nfl_conferences = [
  { abbr: "AFC", name: "American Football Conference", display_name: "AFC" },
  { abbr: "NFC", name: "National Football Conference", display_name: "NFC" }
]

nfl_conferences.each do |conf_data|
  conf = nfl.conferences.find_or_create_by!(abbr: conf_data[:abbr]) do |c|
    c.name = conf_data[:name]
    c.display_name = conf_data[:display_name]
  end
  puts "  ✓ #{conf.display_name} (NFL)"
end

# ============================================================================
# NCAA FOOTBALL BOWL SUBDIVISION CONFERENCES
# ============================================================================

fbs_conferences = [
  { abbr: "AAC", name: "American Conference", display_name: "American" },
  { abbr: "ACC", name: "Atlantic Coast Conference", display_name: "Atlantic Coast" },
  { abbr: "B12", name: "Big 12 Conference", display_name: "Big 12" },
  { abbr: "B1G", name: "Big Ten Conference", display_name: "Big Ten" },
  { abbr: "CUSA", name: "Conference USA", display_name: "Conference USA" },
  { abbr: "IND", name: "FBS Independents", display_name: "Independent" },
  { abbr: "MAC", name: "Mid-American Conference", display_name: "Mid-American" },
  { abbr: "MWC", name: "Mountain West Conference", display_name: "Mountain West" },
  { abbr: "PAC", name: "Pac-12 Conference", display_name: "Pac-12" },
  { abbr: "SEC", name: "Southeastern Conference", display_name: "Southeastern" },
  { abbr: "SUN", name: "Sun Belt Conference", display_name: "Sun Belt" }
]

fbs_conferences.each do |conf_data|
  conf = fbs.conferences.find_or_create_by!(abbr: conf_data[:abbr]) do |c|
    c.name = conf_data[:name]
    c.display_name = conf_data[:display_name]
  end
  puts "  ✓ #{conf.display_name} (FBS)"
end

# ============================================================================
# NCAA FOOTBALL CHAMPIONSHIP SUBDIVISION CONFERENCES
# ============================================================================

fcs_conferences = [
  { abbr: "BSKY", name: "Big Sky Conference", display_name: "Big Sky" },
  { abbr: "CAA", name: "Coastal Athletic Association", display_name: "Coastal" },
  { abbr: "IND", name: "FCS Independents", display_name: "Independents" },
  { abbr: "IVY", name: "Ivy League", display_name: "Ivy" },
  { abbr: "MEAC", name: "Mid-Eastern Athletic Conference", display_name: "Mid-Eastern" },
  { abbr: "MVC", name: "Missouri Valley Football Conference", display_name: "Missouri Valley" },
  { abbr: "NEC", name: "Northeast Conference", display_name: "Northeast" },
  { abbr: "OVCS", name: "OVC-Big South Association", display_name: "OVC - Big South" },
  { abbr: "PAT", name: "Patriot League", display_name: "Patriot League" },
  { abbr: "PIO", name: "Pioneer Football League", display_name: "Pioneer" },
  { abbr: "SOU", name: "Southern Conference", display_name: "Southern" },
  { abbr: "SLND", name: "Southland Conference", display_name: "Southland" },
  { abbr: "SWAC", name: "Southwestern Athletic Conference", display_name: "Southwestern" },
  { abbr: "UAC", name: "United Athletic Conference", display_name: "United" }
]

fcs_conferences.each do |conf_data|
  conf = fcs.conferences.find_or_create_by!(abbr: conf_data[:abbr]) do |c|
    c.name = conf_data[:name]
    c.display_name = conf_data[:display_name]
  end
  puts "  ✓ #{conf.display_name} (FCS)"
end

# ============================================================================
# TEAMS - Use `rake seeds:import` to import from db/seeds/teams.yml
# ============================================================================
# Teams are NOT seeded here to avoid conflicts with the YAML import.
# The YAML file is the single source of truth for team data.

puts "\nSeed completed!"
puts "Summary:"
puts "  Leagues: #{League.count}"
puts "  Conferences: #{Conference.count}"
puts "  Teams: #{Team.count} (run `rake seeds:import` to import from YAML)"
