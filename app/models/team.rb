class Team < ApplicationRecord
  BRAND_SEARCH_URL = "https://www.google.com/search?q="

  has_many :affiliations, dependent: :destroy
  has_many :leagues, through: :affiliations
  has_many :conferences, through: :affiliations
  has_many :colors, dependent: :destroy
  has_many :styles, dependent: :destroy
  has_many :home_games, class_name: "Game", foreign_key: "home_team_id", dependent: :restrict_with_error
  has_many :away_games, class_name: "Game", foreign_key: "away_team_id", dependent: :restrict_with_error

  validates :name, presence: true
  validates :location, presence: true
  validates :level, inclusion: { in: %w[college pro], message: "must be either 'college' or 'pro'" }, allow_nil: true

  scope :alphabetical, -> { order(:location, :name) }
  scope :latest_first, -> { order(created_at: :desc) }
  scope :by_level, ->(level) { where(level: level) }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    %w[abbr created_at display_location level location name updated_at
       colors_count styles_count affiliations_count]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[affiliations colors styles]
  end

  # Virtual attributes for sorting by association counts
  ransacker :colors_count do
    Arel.sql("(SELECT COUNT(*) FROM colors WHERE colors.team_id = teams.id)")
  end

  ransacker :styles_count do
    Arel.sql("(SELECT COUNT(*) FROM styles WHERE styles.team_id = teams.id)")
  end

  ransacker :affiliations_count do
    Arel.sql("(SELECT COUNT(*) FROM affiliations WHERE affiliations.team_id = teams.id)")
  end

  def games
    Game.where("home_team_id = ? OR away_team_id = ?", id, id)
  end

  def full_name
    "#{location} #{name}"
  end

  def display_name(league: nil)
    gender_name = name
    if !league.nil? && league.gender == "women" && !womens_name.blank?
      gender_name = womens_name
    end

    "#{display_location || location} #{gender_name}"
  end

  def brand_search_query
    BRAND_SEARCH_URL + (location + " brand colors").split(" ").compact.join("+")
  end

  # Generates ESPN-style slug: display_location-name
  # e.g., "st-bonaventure-bonnies"
  # Uses transliterate to convert accented characters (é→e, ñ→n) to ASCII
  def generate_espn_slug
    slug = "#{display_location || location} #{name}"
    ActiveSupport::Inflector.transliterate(slug).downcase.gsub(/[''&]/, '').gsub(/[^a-z0-9]+/, '-').gsub(/-$/, '')
  end

  # Generates slug for SCSS naming: abbr-display_location-name
  # e.g., "tuln-tulane-green-wave"
  # Uses transliterate to convert accented characters (é→e, ñ→n) to ASCII
  def scss_slug
    [ abbr, display_location || location, name ].compact.map { |s|
      ActiveSupport::Inflector.transliterate(s).downcase.gsub(/[^a-z0-9]+/, "-").gsub(/-+$/, "")
    }.join("-")
  end

  # Full prefix for SCSS variables/classes
  # e.g., "tuln-tulane-green-wave"
  def scss_prefix
    scss_slug
  end

  ## Get a team's default css class name
  # Uses Ruby find to work with preloaded associations instead of generating SQL
  def get_default_style
    styles.find { |s| s.default } || styles.first
  end

  def get_default_style_class_name
    style = get_default_style
    if style
      style.scss_class_name
    else
      ""
    end
  end

  # Returns the most recent past game date for this team (for "last used" display)
  # Optionally scoped to a specific event
  def last_game_date(event: nil)
    scope = games.where("starts_at <= ?", Time.current)
    scope = scope.where(event: event) if event
    scope.maximum(:starts_at)
  end
end
