# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding sports structure..."

# ============================================================================
# LEAGUES
# ============================================================================

# NCAA Men's Basketball
ncaa_mbb = League.find_or_create_by!(abbr: "NCAAMBB") do |l|
  l.name = "Men's College Basketball"
  l.sport = "basketball"
  l.gender = "men"
  l.level = "college"
  l.periods = 2
end
puts "✓ #{ncaa_mbb.name}"

# NCAA Women's Basketball
ncaa_wbb = League.find_or_create_by!(abbr: "NCAAWBB") do |l|
  l.name = "Women's College Basketball"
  l.sport = "basketball"
  l.gender = "women"
  l.level = "college"
  l.periods = 4
  l.quarters_score_as_halves = true
end
puts "✓ #{ncaa_wbb.name}"

# NCAA Football Bowl Subdivision
ncaa_fbs = League.find_or_create_by!(abbr: "FBS") do |l|
  l.name = "NCAA Football Bowl Subdivision"
  l.sport = "football"
  l.gender = "men"
  l.level = "college"
  l.periods = 4
end
puts "✓ #{ncaa_fbs.name}"

# ============================================================================
# MEN'S BASKETBALL CONFERENCES
# ============================================================================

mbb_conferences = [
  { name: "America East Conference", display_name: "America East", abbr: "AEAST" },
  { name: "American Conference", display_name: "American", abbr: "AAC" },
  { name: "Atlantic Sun Conference", display_name: "Atlantic Sun", abbr: "ASUN" },
  { name: "Atlantic 10 Conference", display_name: "Atlantic 10", abbr: "A10" },
  { name: "Atlantic Coast Conference", display_name: "Atlantic Coast", abbr: "ACC" },
  { name: "Big 12 Conference", display_name: "Big 12", abbr: "B12" },
  { name: "Big East Conference", display_name: "Big East", abbr: "BIGEAST" },
  { name: "Big Sky Conference", display_name: "Big Sky", abbr: "SKY" },
  { name: "Big South Conference", display_name: "Big South", abbr: "BSOUTH" },
  { name: "Big Ten Conference", display_name: "Big Ten", abbr: "B1G" },
  { name: "Big West Conference", display_name: "Big West", abbr: "BWEST" },
  { name: "Coastal Athletic Association", display_name: "Coastal", abbr: "CAA" },
  { name: "Conference USA", display_name: "Conference USA", abbr: "CUSA" },
  { name: "Horizon League", display_name: "Horizon League", abbr: "HORIZ" },
  { name: "Ivy League", display_name: "Ivy League", abbr: "IVY" },
  { name: "Metro Atlantic Athletic Conference", display_name: "Metro Atlantic", abbr: "METRO" },
  { name: "Mid-American Conference", display_name: "Mid-American", abbr: "MAC" },
  { name: "Mid-Eastern Athletic Conference", display_name: "Mid-Eastern", abbr: "MEAC" },
  { name: "Missouri Valley Conference", display_name: "Missouri Valley", abbr: "MVC" },
  { name: "Mountain West Conference", display_name: "Mountain West", abbr: "MWC" },
  { name: "Northeast Conference", display_name: "Northeast", abbr: "NEC" },
  { name: "Ohio Valley Conference", display_name: "Ohio Valley", abbr: "OVC" },
  { name: "Patriot League", display_name: "Patriot League", abbr: "PAT" },
  { name: "Southeastern Conference", display_name: "Southeastern", abbr: "SEC" },
  { name: "Southern Conference", display_name: "Southern", abbr: "SOU" },
  { name: "Southland Conference", display_name: "Southland", abbr: "SLND" },
  { name: "Southwestern Athletic Conference", display_name: "Southwestern", abbr: "SWAC" },
  { name: "Summit League", display_name: "Summit League", abbr: "SUM" },
  { name: "Sun Belt Conference", display_name: "Sun Belt", abbr: "SUN" },
  { name: "West Coast Conference", display_name: "West Coast", abbr: "WCC" },
  { name: "Western Athletic Conference", display_name: "Western", abbr: "WEST" }
]

mbb_conferences.each do |conf_data|
  conf = ncaa_mbb.conferences.find_or_create_by!(abbr: conf_data[:abbr]) do |c|
    c.name = conf_data[:name]
    c.display_name = conf_data[:display_name]
  end
  puts "  ✓ #{conf.display_name} (MBB)"
end

# ============================================================================
# WOMEN'S BASKETBALL CONFERENCES
# ============================================================================

wbb_conferences = [
  { name: "America East Conference", display_name: "America East", abbr: "AEAST" },
  { name: "American Conference", display_name: "American", abbr: "AAC" },
  { name: "Atlantic Sun Conference", display_name: "Atlantic Sun", abbr: "ASUN" },
  { name: "Atlantic 10 Conference", display_name: "Atlantic 10", abbr: "A10" },
  { name: "Atlantic Coast Conference", display_name: "Atlantic Coast", abbr: "ACC" },
  { name: "Big 12 Conference", display_name: "Big 12", abbr: "B12" },
  { name: "Big East Conference", display_name: "Big East", abbr: "BIGEAST" },
  { name: "Big Sky Conference", display_name: "Big Sky", abbr: "BSKY" },
  { name: "Big South Conference", display_name: "Big South", abbr: "BSOUTH" },
  { name: "Big Ten Conference", display_name: "Big Ten", abbr: "B1G" },
  { name: "Big West Conference", display_name: "Big West", abbr: "BWEST" },
  { name: "Coastal Athletic Association", display_name: "Coastal", abbr: "CAA" },
  { name: "Conference USA", display_name: "Conference USA", abbr: "CUSA" },
  { name: "Horizon League", display_name: "Horizon League", abbr: "HORIZ" },
  { name: "Ivy League", display_name: "Ivy League", abbr: "IVY" },
  { name: "Metro Atlantic Athletic Conference", display_name: "Metro Atlantic", abbr: "METRO" },
  { name: "Mid-American Conference", display_name: "Mid-American", abbr: "MAC" },
  { name: "Mid-Eastern Athletic Conference", display_name: "Mid-Eastern", abbr: "MEAC" },
  { name: "Missouri Valley Conference", display_name: "Missouri Valley", abbr: "MVC" },
  { name: "Mountain West Conference", display_name: "Mountain West", abbr: "MWC" },
  { name: "Northeast Conference", display_name: "Northeast", abbr: "NEC" },
  { name: "Ohio Valley Conference", display_name: "Ohio Valley", abbr: "OVC" },
  { name: "Patriot League", display_name: "Patriot League", abbr: "PAT" },
  { name: "Southeastern Conference", display_name: "Southeastern", abbr: "SEC" },
  { name: "Southern Conference", display_name: "Southern", abbr: "SOU" },
  { name: "Southland Conference", display_name: "Southland", abbr: "SLND" },
  { name: "Southwestern Athletic Conference", display_name: "Southwestern", abbr: "SWAC" },
  { name: "Summit League", display_name: "Summit League", abbr: "SUM" },
  { name: "Sun Belt Conference", display_name: "Sun Belt", abbr: "SUN" },
  { name: "West Coast Conference", display_name: "West Coast", abbr: "WCC" },
  { name: "Western Athletic Conference", display_name: "Western", abbr: "WEST" }
]

wbb_conferences.each do |conf_data|
  conf = ncaa_wbb.conferences.find_or_create_by!(abbr: conf_data[:abbr]) do |c|
    c.name = conf_data[:name]
    c.display_name = conf_data[:display_name]
  end
  puts "  ✓ #{conf.display_name} (WBB)"
end

# ============================================================================
# FBS FOOTBALL CONFERENCES
# ============================================================================

fbs_conferences = [
  { name: "American Conference", display_name: "American", abbr: "AAC" },
  { name: "Atlantic Coast Conference", display_name: "Atlantic Coast", abbr: "ACC" },
  { name: "Big 12 Conference", display_name: "Big 12", abbr: "B12" },
  { name: "Big Ten Conference", display_name: "Big Ten", abbr: "B1G" },
  { name: "Conference USA", display_name: "Conference USA", abbr: "CUSA" },
  { name: "FBS Independents", display_name: "Independent", abbr: "IND" },
  { name: "Mid-American Conference", display_name: "Mid-American", abbr: "MAC" },
  { name: "Mountain West Conference", display_name: "Mountain West", abbr: "MWC" },
  { name: "Pac-12 Conference", display_name: "Pac-12", abbr: "PAC" },
  { name: "Southeastern Conference", display_name: "Southeastern", abbr: "SEC" },
  { name: "Sun Belt Conference", display_name: "Sun Belt", abbr: "SUN" }
]

fbs_conferences.each do |conf_data|
  conf = ncaa_fbs.conferences.find_or_create_by!(abbr: conf_data[:abbr]) do |c|
    c.name = conf_data[:name]
    c.display_name = conf_data[:display_name]
  end
  puts "  ✓ #{conf.display_name} (FBS)"
end

# ============================================================================
# TEAMS
# ============================================================================

tulane = Team.find_or_create_by!(location: "Tulane", name: "Green Wave") do |t|
  t.abbr = "TULN"
  t.prefix = ""
  t.suffix = "University"
  t.display_location = "Tulane"
  t.womens_name = ""
  t.level = "college"
  t.brand_info = "https://tulane.app.box.com/s/rxqmxdzl4bw9zhufst2bl..."
end
puts "  ✓ #{tulane.display_name}"

puts "\nSeed completed!"
puts "Summary:"
puts "  Leagues: #{League.count}"
puts "  Conferences: #{Conference.count}"
puts "  Divisions: #{Division.count}"
puts "  Teams: #{Team.count}"
