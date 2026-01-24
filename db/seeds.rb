# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding sports structure..."

# ============================================================================
# LEAGUES
# ============================================================================

# NCAA Men's Division I Basketball
ncaambb = League.find_or_create_by!(abbr: "NCAAMBB") do |l|
  l.name = "NCAA Men's Division I Basketball"
  l.sport = "basketball"
  l.gender = "men"
  l.level = "college"
  l.periods = 2
end
puts "✓ #{ncaambb.name}"

# NCAA Women's Division I Basketball
ncaawbb = League.find_or_create_by!(abbr: "NCAAWBB") do |l|
  l.name = "NCAA Women's Division I Basketball"
  l.sport = "basketball"
  l.gender = "women"
  l.level = "college"
  l.periods = 4
  l.quarters_score_as_halves = true
end
puts "✓ #{ncaawbb.name}"

# National Football League
nfl = League.find_or_create_by!(abbr: "NFL") do |l|
  l.name = "National Football League"
  l.sport = "football"
  l.gender = "men"
  l.level = "pro"
  l.periods = 4
end
puts "✓ #{nfl.name}"

# NCAA Football Bowl Subdivision
fbs = League.find_or_create_by!(abbr: "FBS") do |l|
  l.name = "NCAA Football Bowl Subdivision"
  l.sport = "football"
  l.gender = "men"
  l.level = "college"
  l.periods = 4
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

ncaambb_conferences = [
  { name: "Atlantic 10 Conference", display_name: "Atlantic 10", abbr: "A10" },
  { name: "American Conference", display_name: "American", abbr: "AAC" },
  { name: "Atlantic Coast Conference", display_name: "Atlantic Coast", abbr: "ACC" },
  { name: "America East Conference", display_name: " America East", abbr: "AEAST" },
  { name: "Atlantic Sun Conference", display_name: "Atlantic Sun", abbr: "ASUN" },
  { name: "Big 12 Conference", display_name: "Big 12", abbr: "B12" },
  { name: "Big Ten Conference", display_name: "Big Ten", abbr: "B1G" },
  { name: "Big East Conference", display_name: "Big East", abbr: "BIGEAST" },
  { name: "Big South Conference", display_name: "Big South", abbr: "BSOUTH" },
  { name: "Big West Conference", display_name: "Big West", abbr: "BWEST" },
  { name: "Coastal Athletic Association", display_name: "Coastal ", abbr: "CAA" },
  { name: "Conference USA", display_name: " Conference USA", abbr: "CUSA" },
  { name: "Horizon League", display_name: " Horizon League", abbr: "HORIZ" },
  { name: "Ivy League", display_name: " Ivy League", abbr: "IVY" },
  { name: "Mid-American Conference", display_name: "Mid-American", abbr: "MAC" },
  { name: "Mid-Eastern Athletic Conference", display_name: "Mid-Eastern", abbr: "MEAC" },
  { name: "Metro Atlantic Athletic Conference", display_name: "Metro Atlantic", abbr: "METRO" },
  { name: "Missouri Valley Conference", display_name: "Missouri Valley", abbr: "MVC" },
  { name: "Mountain West Conference", display_name: "Mountain West", abbr: "MWC" },
  { name: "Northeast Conference", display_name: "Northeast", abbr: "NEC" },
  { name: "Ohio Valley Conference", display_name: "Ohio Valley", abbr: "OVC" },
  { name: "Patriot League", display_name: "Patriot League", abbr: "PAT" },
  { name: "Southeastern Conference", display_name: "Southeastern", abbr: "SEC" },
  { name: "Big Sky Conference", display_name: "Big Sky", abbr: "SKY" },
  { name: "Southland Conference", display_name: "Southland", abbr: "SLND" },
  { name: "Southern Conference", display_name: "Southern", abbr: "SOU" },
  { name: "Summit League", display_name: "Summit", abbr: "SUM" },
  { name: "Sun Belt Conference", display_name: "Sun Belt", abbr: "SUN" },
  { name: "Southwestern Athletic Conference", display_name: "Southwestern", abbr: "SWAC" },
  { name: "West Coast Conference", display_name: "West Coast", abbr: "WCC" },
  { name: "Western Athletic Conference", display_name: "Western", abbr: "WEST" },
]

ncaambb_conferences.each do |conf_data|
  conf = ncaambb.conferences.find_or_create_by!(abbr: conf_data[:abbr]) do |c|
    c.name = conf_data[:name]
    c.display_name = conf_data[:display_name]
  end
  puts "  ✓ #{conf.display_name} (MBB)"
end

# ============================================================================
# NCAA WOMEN'S DIVISION I BASKETBALL CONFERENCES
# ============================================================================

ncaawbb_conferences = [
  { name: "Atlantic 10 Conference", display_name: "Atlantic 10", abbr: "A10" },
  { name: "American Conference", display_name: "American", abbr: "AAC" },
  { name: "Atlantic Coast Conference", display_name: "Atlantic Coast", abbr: "ACC" },
  { name: "America East Conference", display_name: "America East", abbr: "AEAST" },
  { name: "Atlantic Sun Conference", display_name: "Atlantic Sun", abbr: "ASUN" },
  { name: "Big 12 Conference ", display_name: "Big 12", abbr: "B12" },
  { name: "Big Ten Conference", display_name: "Big Ten", abbr: "B1G" },
  { name: "Big East Conference", display_name: "Big East", abbr: "BIGEAST" },
  { name: "Big Sky Conference", display_name: "Big Sky", abbr: "BSKY" },
  { name: "Big South Conference ", display_name: "Big South", abbr: "BSOUTH" },
  { name: "Big West Conference", display_name: "Big West", abbr: "BWEST" },
  { name: "Coastal Athletic Association", display_name: "Coastal", abbr: "CAA" },
  { name: "Conference USA", display_name: "Conference USA", abbr: "CUSA" },
  { name: "Horizon League", display_name: "Horizon League", abbr: "HORIZ" },
  { name: "Ivy League", display_name: "Ivy League", abbr: "IVY" },
  { name: "Mid-American Conference", display_name: "Mid-American", abbr: "MAC" },
  { name: "Mid-Eastern Athletic Conference", display_name: "Mid-Eastern", abbr: "MEAC" },
  { name: "Metro Atlantic Athletic Conference", display_name: "Metro Atlantic", abbr: "METRO" },
  { name: "Missouri Valley Conference", display_name: "Missouri Valley", abbr: "MVC" },
  { name: "Mountain West Conference", display_name: "Mountain West", abbr: "MWC" },
  { name: "Northeast Conference", display_name: "Northeast", abbr: "NEC" },
  { name: "Ohio Valley Conference", display_name: "Ohio Valley", abbr: "OVC" },
  { name: "Patriot League", display_name: "Patriot League", abbr: "PAT" },
  { name: "Southeastern Conference", display_name: "Southeastern", abbr: "SEC" },
  { name: "Southland Conference", display_name: "Southland", abbr: "SLND" },
  { name: "Southern Conference", display_name: "Southern", abbr: "SOU" },
  { name: "Summit League", display_name: "Summit League", abbr: "SUM" },
  { name: "Sun Belt Conference", display_name: "Sun Belt", abbr: "SUN" },
  { name: "Southwestern Athletic Conference", display_name: "Southwestern", abbr: "SWAC" },
  { name: "West Coast Conference", display_name: "West Coast", abbr: "WCC" },
  { name: "Western Athletic Conference", display_name: "Western", abbr: "WEST" },
]

ncaawbb_conferences.each do |conf_data|
  conf = ncaawbb.conferences.find_or_create_by!(abbr: conf_data[:abbr]) do |c|
    c.name = conf_data[:name]
    c.display_name = conf_data[:display_name]
  end
  puts "  ✓ #{conf.display_name} (WBB)"
end

# ============================================================================
# NCAA FOOTBALL BOWL SUBDIVISION CONFERENCES
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
  { name: "Sun Belt Conference", display_name: "Sun Belt", abbr: "SUN" },
]

fbs_conferences.each do |conf_data|
  conf = fbs.conferences.find_or_create_by!(abbr: conf_data[:abbr]) do |c|
    c.name = conf_data[:name]
    c.display_name = conf_data[:display_name]
  end
  puts "  ✓ #{conf.display_name} (FBS)"
end

# ============================================================================
# TEAMS
# ============================================================================

# Alabama - Birmingham Blazers
alabama___birmingham = Team.find_or_create_by!(location: "Alabama - Birmingham", name: "Blazers") do |t|
  t.abbr = "UAB"
  t.display_location = "Alabama - Birmingham"
  t.level = "college"
  t.brand_info = "https://www.uab.edu/toolkit/"
end
puts "  ✓ #{alabama___birmingham.display_name}"

# Arizona State Sun Devils
arizona = Team.find_or_create_by!(location: "Arizona", name: "Sun Devils") do |t|
  t.abbr = "ASU"
  t.display_location = "Arizona State"
  t.level = "college"
  t.brand_info = "https://brandguide.asu.edu/brand-elements/design/color"
end
puts "  ✓ #{arizona.display_name}"

# Arizona Wildcats
arizona = Team.find_or_create_by!(location: "Arizona", name: "Wildcats") do |t|
  t.abbr = "ARI"
  t.display_location = "Arizona"
  t.level = "college"
  t.brand_info = "https://marcom.arizona.edu/brand-guidelines/colors"
end
puts "  ✓ #{arizona.display_name}"

# Baylor Bears
baylor = Team.find_or_create_by!(location: "Baylor", name: "Bears") do |t|
  t.abbr = "BAY"
  t.display_location = "Baylor"
  t.level = "college"
  t.brand_info = "https://brand.web.baylor.edu/brand-standards/official-brand-colors"
end
puts "  ✓ #{baylor.display_name}"

# Boston College Eagles
boston = Team.find_or_create_by!(location: "Boston", name: "Eagles") do |t|
  t.abbr = "BC"
  t.display_location = "Boston College"
  t.level = "college"
  t.brand_info = "https://bceagles.com/documents/2023/8/2/BC_Athletics_Style_Guide.pdf"
end
puts "  ✓ #{boston.display_name}"

# Brigham Young Cougars
brigham_young = Team.find_or_create_by!(location: "Brigham Young", name: "Cougars") do |t|
  t.abbr = "BYU"
  t.display_location = "Brigham Young"
  t.level = "college"
  t.brand_info = "https://brand.byu.edu/colors"
end
puts "  ✓ #{brigham_young.display_name}"

# California Golden Bears
california = Team.find_or_create_by!(location: "California", name: "Golden Bears") do |t|
  t.abbr = "CAL"
  t.display_location = "California"
  t.level = "college"
  t.brand_info = "https://brand.berkeley.edu/visual-identity/colors/"
end
puts "  ✓ #{california.display_name}"

# Central Florida Knights
central_florida = Team.find_or_create_by!(location: "Central Florida", name: "Knights") do |t|
  t.abbr = "UCF"
  t.display_location = "Central Florida"
  t.level = "college"
  t.brand_info = "https://www.ucf.edu/brand/brand-assets/colors/"
end
puts "  ✓ #{central_florida.display_name}"

# Cincinnati Bearcats
cincinnati = Team.find_or_create_by!(location: "Cincinnati", name: "Bearcats") do |t|
  t.abbr = "CIN"
  t.display_location = "Cincinnati"
  t.level = "college"
  t.brand_info = "https://www.uc.edu/about/marketing-communications/brand-guide/visual-identity/color.html"
end
puts "  ✓ #{cincinnati.display_name}"

# Clemson Tigers
clemson = Team.find_or_create_by!(location: "Clemson", name: "Tigers") do |t|
  t.abbr = "CLEM"
  t.display_location = "Clemson"
  t.level = "college"
  t.brand_info = "https://www.clemson.edu/brand/color/"
end
puts "  ✓ #{clemson.display_name}"

# Colorado Buffaloes
colorado = Team.find_or_create_by!(location: "Colorado", name: "Buffaloes") do |t|
  t.abbr = "COL"
  t.display_location = "Colorado"
  t.level = "college"
  t.brand_info = "https://www.cu.edu/brand-and-identity-guidelines/color-specifications"
end
puts "  ✓ #{colorado.display_name}"

# Duke Blue Devils
duke = Team.find_or_create_by!(location: "Duke", name: "Blue Devils") do |t|
  t.abbr = "DUKE"
  t.display_location = "Duke"
  t.level = "college"
  t.brand_info = "https://brand.duke.edu/colors/"
end
puts "  ✓ #{duke.display_name}"

# East Carolina Pirates
east_carolina = Team.find_or_create_by!(location: "East Carolina", name: "Pirates") do |t|
  t.abbr = "ECU"
  t.display_location = "East Carolina"
  t.level = "college"
  t.brand_info = "https://brand.ecu.edu/"
end
puts "  ✓ #{east_carolina.display_name}"

# Florida Atlantic Owls
florida_atlantic = Team.find_or_create_by!(location: "Florida Atlantic", name: "Owls") do |t|
  t.abbr = "FAU"
  t.display_location = "Florida Atlantic"
  t.level = "college"
  t.brand_info = "https://www.fau.edu/styleguide/colors/"
end
puts "  ✓ #{florida_atlantic.display_name}"

# Florida State Seminoles
florida_state = Team.find_or_create_by!(location: "Florida State", name: "Seminoles") do |t|
  t.abbr = "FSU"
  t.display_location = "Florida State"
  t.level = "college"
  t.brand_info = "https://brand.fsu.edu/web/colors"
end
puts "  ✓ #{florida_state.display_name}"

# Georgia Tech Yellow Jackets
georgia = Team.find_or_create_by!(location: "Georgia", name: "Yellow Jackets") do |t|
  t.abbr = "GT"
  t.display_location = "Georgia Tech"
  t.level = "college"
  t.brand_info = "https://brand.gatech.edu/our-look/colors"
end
puts "  ✓ #{georgia.display_name}"

# Houston Cougars
houston = Team.find_or_create_by!(location: "Houston", name: "Cougars") do |t|
  t.abbr = "HOU"
  t.display_location = "Houston"
  t.level = "college"
  t.brand_info = "https://www.uh.edu/brand/brand-identity/style-guide/index.php"
end
puts "  ✓ #{houston.display_name}"

# Iowa State Cyclones
iowa = Team.find_or_create_by!(location: "Iowa", name: "Cyclones") do |t|
  t.abbr = "ISU"
  t.display_location = "Iowa State"
  t.level = "college"
  t.brand_info = "https://www.brandmarketing.iastate.edu/brand-elements/color-palette/"
end
puts "  ✓ #{iowa.display_name}"

# Kansas Jayhawks
kansas = Team.find_or_create_by!(location: "Kansas", name: "Jayhawks") do |t|
  t.abbr = "KU"
  t.display_location = "Kansas"
  t.level = "college"
  t.brand_info = "https://brand.ku.edu/guidelines/design/color"
end
puts "  ✓ #{kansas.display_name}"

# Kansas State Wildcats
kansas = Team.find_or_create_by!(location: "Kansas", name: "Wildcats") do |t|
  t.abbr = "KSU"
  t.display_location = "Kansas State"
  t.level = "college"
  t.brand_info = "https://www.k-state.edu/communications-marketing/brand-style/visual-language/color/"
end
puts "  ✓ #{kansas.display_name}"

# Louisville Cardinals
louisville = Team.find_or_create_by!(location: "Louisville", name: "Cardinals") do |t|
  t.abbr = "LOU"
  t.display_location = "Louisville"
  t.level = "college"
  t.brand_info = "https://louisville.edu/brand/visual/color"
end
puts "  ✓ #{louisville.display_name}"

# Memphis Tigers
memphis = Team.find_or_create_by!(location: "Memphis", name: "Tigers") do |t|
  t.abbr = "MEM"
  t.display_location = "Memphis"
  t.level = "college"
  t.brand_info = "https://www.memphis.edu/communications/brand/colors.php"
end
puts "  ✓ #{memphis.display_name}"

# Miami Hurricanes
miami = Team.find_or_create_by!(location: "Miami", name: "Hurricanes") do |t|
  t.abbr = "MIA"
  t.display_location = "Miami"
  t.level = "college"
  t.brand_info = "https://webcomm.miami.edu/resources/identity/color/index.html"
end
puts "  ✓ #{miami.display_name}"

# Army Black Knights
military_academy = Team.find_or_create_by!(location: "Military Academy", name: "Black Knights") do |t|
  t.abbr = "ARMY"
  t.display_location = "Army"
  t.level = "college"
  t.brand_info = "https://goarmywestpoint.com/news/2015/4/13/Army_West_Point_Athletics_Unveils_Brand_Identity"
end
puts "  ✓ #{military_academy.display_name}"

# Navy Midshipmen
naval_academy = Team.find_or_create_by!(location: "Naval Academy", name: "Midshipmen") do |t|
  t.abbr = "NAVY"
  t.display_location = "Navy"
  t.level = "college"
  t.brand_info = "https://navysports.com/sports/2022/12/21/logos-style-sheet.aspx"
end
puts "  ✓ #{naval_academy.display_name}"

# North Carolina Tar Heels
north_carolina = Team.find_or_create_by!(location: "North Carolina", name: "Tar Heels") do |t|
  t.abbr = "UNC"
  t.display_location = "North Carolina"
  t.level = "college"
  t.brand_info = "https://identity.unc.edu/brand/color-palette/"
end
puts "  ✓ #{north_carolina.display_name}"

# Charlotte 49ers
north_carolina___charlotte = Team.find_or_create_by!(location: "North Carolina - Charlotte", name: "49ers") do |t|
  t.abbr = "CHA"
  t.display_location = "Charlotte"
  t.level = "college"
  t.brand_info = "https://brand.charlotte.edu/visual-identity/color-palette/"
end
puts "  ✓ #{north_carolina___charlotte.display_name}"

# NC State Wolfpack
north_carolina_state = Team.find_or_create_by!(location: "North Carolina State", name: "Wolfpack") do |t|
  t.abbr = "NCST"
  t.display_location = "NC State"
  t.level = "college"
  t.brand_info = "https://brand.ncsu.edu/designing-for-nc-state/color/"
end
puts "  ✓ #{north_carolina_state.display_name}"

# North Texas Mean Green
north_texas = Team.find_or_create_by!(location: "North Texas", name: "Mean Green") do |t|
  t.abbr = "UNT"
  t.display_location = "North Texas"
  t.level = "college"
  t.brand_info = "https://www.untsystem.edu/offices/marketing-and-communications/documents/unts-styleguide-19-20.pdf"
end
puts "  ✓ #{north_texas.display_name}"

# Notre Dame Fighting Irish
notre_dame = Team.find_or_create_by!(location: "Notre Dame", name: "Fighting Irish") do |t|
  t.abbr = "ND"
  t.display_location = "Notre Dame"
  t.level = "college"
  t.brand_info = "https://onmessage.nd.edu/university-branding/colors/"
end
puts "  ✓ #{notre_dame.display_name}"

# Oklahoma State Cowboys
oklahoma = Team.find_or_create_by!(location: "Oklahoma", name: "Cowboys") do |t|
  t.abbr = "OSU"
  t.display_location = "Oklahoma State"
  t.womens_name = "Cowgirls"
  t.level = "college"
  t.brand_info = "https://brand.okstate.edu/branding-guidelines/colors/"
end
puts "  ✓ #{oklahoma.display_name}"

# Pitt Panthers
pittsburgh = Team.find_or_create_by!(location: "Pittsburgh", name: "Panthers") do |t|
  t.abbr = "PIT"
  t.display_location = "Pitt"
  t.level = "college"
  t.brand_info = "https://www.brand.pitt.edu/brand-elements/color-palettes"
end
puts "  ✓ #{pittsburgh.display_name}"

# Rice Owls
rice = Team.find_or_create_by!(location: "Rice", name: "Owls") do |t|
  t.abbr = "RICE"
  t.display_location = "Rice"
  t.level = "college"
  t.brand_info = "https://brand.rice.edu/colors"
end
puts "  ✓ #{rice.display_name}"

# South Florida Bulls
south_florida = Team.find_or_create_by!(location: "South Florida", name: "Bulls") do |t|
  t.abbr = "USF"
  t.display_location = "South Florida"
  t.level = "college"
  t.brand_info = "https://www.usf.edu/ucm/marketing/colors.aspx"
end
puts "  ✓ #{south_florida.display_name}"

# Southern Methodist Mustangs
southern_methodist = Team.find_or_create_by!(location: "Southern Methodist", name: "Mustangs") do |t|
  t.abbr = "SMU"
  t.display_location = "Southern Methodist"
  t.level = "college"
  t.brand_info = "https://www.smu.edu/brand/color-palette"
end
puts "  ✓ #{southern_methodist.display_name}"

# Stanford Cardinal
stanford = Team.find_or_create_by!(location: "Stanford", name: "Cardinal") do |t|
  t.abbr = "STAN"
  t.display_location = "Stanford"
  t.level = "college"
  t.brand_info = "https://identity.stanford.edu/design-elements/color/"
end
puts "  ✓ #{stanford.display_name}"

# Syracuse Orange
syracuse = Team.find_or_create_by!(location: "Syracuse", name: "Orange") do |t|
  t.abbr = "SYR"
  t.display_location = "Syracuse"
  t.level = "college"
  t.brand_info = "https://designsystem.syr.edu/documentation/design-tokens/color/"
end
puts "  ✓ #{syracuse.display_name}"

# Temple Owls
temple = Team.find_or_create_by!(location: "Temple", name: "Owls") do |t|
  t.abbr = "TEM"
  t.display_location = "Temple"
  t.level = "college"
  t.brand_info = "https://www.temple.edu/sites/www/files/CLC_Art_Sheet_Update_-_May_2021.pdf"
end
puts "  ✓ #{temple.display_name}"

# Texas Christian Horned Frogs
texas = Team.find_or_create_by!(location: "Texas", name: "Horned Frogs") do |t|
  t.abbr = "TCU"
  t.display_location = "Texas Christian"
  t.level = "college"
  t.brand_info = "https://brand.tcu.edu/university-color/"
end
puts "  ✓ #{texas.display_name}"

# Texas - San Antonio Roadrunners
texas___san_antonio = Team.find_or_create_by!(location: "Texas - San Antonio", name: "Roadrunners") do |t|
  t.abbr = "UTSA"
  t.display_location = "Texas - San Antonio"
  t.level = "college"
  t.brand_info = "https://hcap.utsa.edu/documents/ut-san-antonio-brand-guidelines_book-july25.pdf"
end
puts "  ✓ #{texas___san_antonio.display_name}"

# Texas Tech Red Raiders
texas_tech = Team.find_or_create_by!(location: "Texas Tech", name: "Red Raiders") do |t|
  t.abbr = "TTU"
  t.display_location = "Texas Tech"
  t.level = "college"
  t.brand_info = "https://www.texastech.edu/identityguidelines/colors.php"
end
puts "  ✓ #{texas_tech.display_name}"

# Tulane Green Wave
tulane = Team.find_or_create_by!(location: "Tulane", name: "Green Wave") do |t|
  t.abbr = "TULN"
  t.display_location = "Tulane"
  t.level = "college"
  t.brand_info = "https://tulane.app.box.com/s/rxqmxdzl4bw9zhufst2blp2qt5xu2p98"
end
puts "  ✓ #{tulane.display_name}"

# Tulsa Golden Hurricane
tulsa = Team.find_or_create_by!(location: "Tulsa", name: "Golden Hurricane") do |t|
  t.abbr = "TUL"
  t.display_location = "Tulsa"
  t.level = "college"
  t.brand_info = "https://tulsahurricane.com/documents/download/2022/2/1/Tulsa_StyleGuide_2022_copy.pdf"
end
puts "  ✓ #{tulsa.display_name}"

# Utah Utes
utah = Team.find_or_create_by!(location: "Utah", name: "Utes") do |t|
  t.abbr = "UTAH"
  t.display_location = "Utah"
  t.level = "college"
  t.brand_info = "https://brand.utah.edu/branding/colors/"
end
puts "  ✓ #{utah.display_name}"

# Virginia Cavaliers
virginia = Team.find_or_create_by!(location: "Virginia", name: "Cavaliers") do |t|
  t.abbr = "VIR"
  t.display_location = "Virginia"
  t.level = "college"
  t.brand_info = "https://brand.virginia.edu/design-assets/colors"
end
puts "  ✓ #{virginia.display_name}"

# Virginia Tech Hokies
virginia_polytechnic = Team.find_or_create_by!(location: "Virginia Polytechnic", name: "Hokies") do |t|
  t.abbr = "VT"
  t.display_location = "Virginia Tech"
  t.level = "college"
  t.brand_info = "https://brand.vt.edu/identity/color.html"
end
puts "  ✓ #{virginia_polytechnic.display_name}"

# Wake Forest Demon Deacons
wake_forest = Team.find_or_create_by!(location: "Wake Forest", name: "Demon Deacons") do |t|
  t.abbr = "WAKE"
  t.display_location = "Wake Forest"
  t.level = "college"
  t.brand_info = "https://brand.wfu.edu/our-brand-identity/color-patterns-papers/"
end
puts "  ✓ #{wake_forest.display_name}"

# Washington Huskies
washington = Team.find_or_create_by!(location: "Washington", name: "Huskies") do |t|
  t.abbr = "UW"
  t.display_location = "Washington"
  t.level = "college"
  t.brand_info = "https://www.washington.edu/brand/brand-elements/colors/"
end
puts "  ✓ #{washington.display_name}"

# West Virginia Mountaineers
west_virginia = Team.find_or_create_by!(location: "West Virginia", name: "Mountaineers") do |t|
  t.abbr = "WVU"
  t.display_location = "West Virginia"
  t.level = "college"
  t.brand_info = "https://scm.wvu.edu/brand/visual-identity/"
end
puts "  ✓ #{west_virginia.display_name}"

puts "\nSeed completed!"
puts "Summary:"
puts "  Leagues: #{League.count}"
puts "  Conferences: #{Conference.count}"
puts "  Teams: #{Team.count}"
