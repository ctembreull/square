module EventsHelper
  # Aggregates all winners for an event, grouped by family
  # Returns array of hashes sorted by total winnings (descending):
  #   { name: "Player Name", family: family_id_or_'charity', total: 150, wins: [Score, ...] }
  def aggregate_winners(event)
    # Load scores directly with all needed associations to avoid N+1 queries
    # View accesses: win.game.title, win.game.starts_at, win.game.league (via winners_label)
    scores = Score.joins(:game)
                  .includes(:winner, game: :league)
                  .where(games: { event_id: event.id })
                  .reject(&:non_scoring)
                  .select(&:winner_id)

    return [] if scores.empty?

    winners = Player.find(scores.map(&:winner_id).uniq)

    score_map = {}
    winners.each do |winner|
      family_key = if winner.is_a?(Charity)
                     "charity"
                   elsif winner.is_a?(Single) || winner.is_a?(Family)
                     winner.id
                   else
                     winner.family_id
                   end

      score_map[winner.id] = {
        name: winner.display_name.presence || winner.name,
        family: family_key,
        total: 0,
        wins: []
      }
    end

    scores.each do |score|
      score_map[score.winner_id][:total] += score.prize || 0
      score_map[score.winner_id][:wins] << score
    end

    score_map.values.sort_by { |k| -k[:total] }
  end
end
