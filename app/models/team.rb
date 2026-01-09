class Team < ApplicationRecord
  has_many :affiliations, dependent: :destroy
  has_many :leagues, through: :affiliations
  has_many :conferences, through: :affiliations
  has_many :divisions, through: :affiliations
  has_many :colors, dependent: :destroy
  has_many :styles, dependent: :destroy
  has_many :home_games, class_name: "Game", foreign_key: "home_team_id", dependent: :restrict_with_error
  has_many :away_games, class_name: "Game", foreign_key: "away_team_id", dependent: :restrict_with_error

  validates :name, presence: true
  validates :location, presence: true
  validates :level, inclusion: { in: %w[college pro], message: "must be either 'college' or 'pro'" }, allow_nil: true

  scope :alphabetical, -> { order(:location, :name) }
  scope :by_level, ->(level) { where(level: level) }

  def games
    Game.where("home_team_id = ? OR away_team_id = ?", id, id)
  end

  def full_name
    [ prefix, location, suffix, name ].compact.join(" ")
  end

  def proper_name
    [ prefix, location, suffix ].compact.join(" ")
  end

  def display_name
    "#{display_location || location} #{name}"
  end
end
