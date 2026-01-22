module GamesHelper
  # Generate TSV of 10x10 grid with player display names
  # Rows = away digit (0-9), Columns = home digit (0-9)
  def grid_tsv(game)
    game.build_map
    rows = []
    (0..9).each do |away|
      row = (0..9).map do |home|
        player = game.get_player_for_score(a: away, h: home)
        player&.display_name || ""
      end
      rows << row.join("\t")
    end
    rows.join("\n")
  end

  # Generate TSV of scores in linescore format
  # Row 1: Away period scores (tab-separated)
  # Row 2: Home period scores (tab-separated)
  def scores_tsv(game)
    scores = game.scores.by_period
    periods = game.league.periods

    away_scores = (1..periods).map do |period|
      score = scores.find { |s| s.period == period }
      score&.away || ""
    end

    home_scores = (1..periods).map do |period|
      score = scores.find { |s| s.period == period }
      score&.home || ""
    end

    [away_scores.join("\t"), home_scores.join("\t")].join("\n")
  end
end
