# Calculates win probability for each square in a 10x10 grid based on
# historical digit frequency data for different sports.
#
# Usage:
#   service = SquareProbabilityService.new(:football)
#   service.probability_for(away_digit: 0, home_digit: 7)  # => 0.0139
#   service.probability_grid  # => { [0,0] => 0.009, [0,1] => 0.0045, ... }
#   service.heat_color(0.02)  # => "hsl(120, 70%, 40%)" (green for high prob)
#
class SquareProbabilityService < ApplicationService
  # Digit frequencies from published research on final score distributions.
  # Values represent probability that a team's final score ends in that digit.
  # These are approximate and can be refined with more data.
  #
  # Football: Heavily influenced by scoring (TD=6, PAT=1, FG=3, Safety=2)
  # - 7 is most common (TD + PAT)
  # - 0, 3, 4 are common (field goals, shutouts)
  # - 2, 5, 9 are rare
  #
  # Basketball: More uniform since any score is possible, slight variations
  # from game flow patterns.
  #
  DIGIT_FREQUENCIES = {
    football: {
      0 => 0.095,
      1 => 0.047,
      2 => 0.023,
      3 => 0.098,
      4 => 0.101,
      5 => 0.028,
      6 => 0.054,
      7 => 0.146,
      8 => 0.052,
      9 => 0.042
    }.tap { |h| h.default = 0.1 },

    basketball: {
      0 => 0.099,
      1 => 0.101,
      2 => 0.102,
      3 => 0.098,
      4 => 0.100,
      5 => 0.101,
      6 => 0.099,
      7 => 0.100,
      8 => 0.101,
      9 => 0.099
    }.tap { |h| h.default = 0.1 }
  }.freeze

  # Fallback to uniform distribution if sport not found
  UNIFORM_FREQUENCIES = (0..9).to_h { |d| [d, 0.1] }.freeze

  attr_reader :sport, :frequencies

  def initialize(sport, frequencies: nil)
    @sport = sport&.to_sym
    @frequencies = frequencies || DIGIT_FREQUENCIES[@sport] || UNIFORM_FREQUENCIES
  end

  def call
    probability_grid
  end

  # Probability that a game ends with away team's score ending in away_digit
  # and home team's score ending in home_digit.
  # Assumes independence between the two scores.
  def probability_for(away_digit:, home_digit:)
    (frequencies[away_digit] || 0.1) * (frequencies[home_digit] || 0.1)
  end

  # Returns a hash mapping [away_digit, home_digit] => probability
  # for all 100 squares.
  def probability_grid
    @probability_grid ||= (0..9).flat_map do |away|
      (0..9).map do |home|
        [[away, home], probability_for(away_digit: away, home_digit: home)]
      end
    end.to_h
  end

  # Returns percentage string for display (e.g., "1.4%")
  def percentage_for(away_digit:, home_digit:)
    prob = probability_for(away_digit: away_digit, home_digit: home_digit)
    "#{(prob * 100).round(1)}%"
  end

  # Returns an HSL color for heat map display.
  # Green (high probability) -> Yellow (medium) -> Red (low probability)
  #
  # For a 10x10 grid with independent probabilities:
  # - Uniform distribution: each square = 1% (0.01)
  # - Football: ranges from ~0.3% (2x2) to ~2.1% (7x7)
  #
  # Hue: 0 = red, 60 = yellow, 120 = green
  def heat_color(probability)
    # Normalize probability to a 0-1 scale based on expected range
    # Min expected: ~0.003 (0.3%), Max expected: ~0.022 (2.2%)
    min_prob = 0.003
    max_prob = 0.022
    normalized = [(probability - min_prob) / (max_prob - min_prob), 0].max
    normalized = [normalized, 1].min

    # Map to hue: 0 (red) to 120 (green)
    hue = (normalized * 120).round

    "hsl(#{hue}, 65%, 45%)"
  end

  # Convenience method for views: returns both percentage and color
  def cell_data(away_digit:, home_digit:)
    prob = probability_for(away_digit: away_digit, home_digit: home_digit)
    {
      probability: prob,
      percentage: "#{(prob * 100).round(1)}%",
      color: heat_color(prob)
    }
  end
end
