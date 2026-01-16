class Score < ApplicationRecord
  belongs_to :game
  belongs_to :winner, class_name: "Player", optional: true

  validates :period, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :period, uniqueness: { scope: :game_id, message: "already has a score for this game" }
  validates :away, numericality: { only_integer: true }, allow_nil: true
  validates :home, numericality: { only_integer: true }, allow_nil: true
  validates :away_total, numericality: { only_integer: true }, allow_nil: true
  validates :home_total, numericality: { only_integer: true }, allow_nil: true
  validates :prize, numericality: { only_integer: true }, allow_nil: true

  scope :by_period, -> { order(period: :asc) }
  scope :complete, -> { where(complete: true) }
  scope :scoring, -> { where(non_scoring: false) }

  # Returns the last digit of the away team's total score (for grid lookup)
  def away_digit
    return nil unless away_total
    away_total % 10
  end

  # Returns the last digit of the home team's total score (for grid lookup)
  def home_digit
    return nil unless home_total
    home_total % 10
  end

  # Returns the grid address for this score (e.g., "a3h7")
  def grid_address
    return nil unless away_total && home_total
    "a#{away_digit}h#{home_digit}"
  end

  # Short period header for scores table (e.g., "1", "2", "3", "4/OT")
  def period_header
    suffix = ot? && period == game.league.periods ? "/OT" : ""
    "#{period}#{suffix}"
  end

  # Period label for winners table (e.g., "1st Quarter", "Final")
  def winners_label
    if period == game.league.periods
      "Final"
    else
      term = game.league.period_term
      "#{period}#{period.ordinal} #{term}"
    end
  end

  # Whether this score awards a prize (non-scoring periods don't)
  def awards_prize?
    !non_scoring? && complete?
  end
end
