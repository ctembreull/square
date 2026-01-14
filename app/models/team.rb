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
    %w[abbr created_at display_location level location name updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[affiliations colors styles]
  end

  def games
    Game.where("home_team_id = ? OR away_team_id = ?", id, id)
  end

  def full_name
    "#{location} #{name}"
  end

  def display_name
    "#{display_location || location} #{name}"
  end

  def brand_search_query
    BRAND_SEARCH_URL + (location + " brand colors").split(" ").compact.join("+")
  end

  # Generates slug for SCSS naming: abbr-display_location-name
  # e.g., "tuln-tulane-green-wave"
  def scss_slug
    [ abbr, display_location || location, name ].compact.map { |s| s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/-+$/, "") }.join("-")
  end

  # Full prefix for SCSS variables/classes
  # e.g., "tuln-tulane-green-wave"
  def scss_prefix
    scss_slug
  end

  ## Get a team's default css class name
  def get_default_style
    style = styles.default.first || styles.first
  end

  def get_default_style_class_name
    style = get_default_style
    if style
      style.scss_class_name
    else
      ""
    end
  end
end
