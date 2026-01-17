class RefreshGameScoresJob < ApplicationJob
  queue_as :default

  def perform(game_id)
    game = Game.find_by(id: game_id)
    return unless game&.score_url.present?
    return if game.completed?

    # Transition from upcoming to in_progress when job runs at game time
    game.start! if game.upcoming?

    is_final = ScoreboardService::ScoreScraper.call(game)
    game.complete! if is_final
    Rails.logger.info "[RefreshGameScoresJob] Completed scrape for game #{game_id}, final=#{is_final}"
  rescue ScoreboardService::ScoreScraper::ScraperError, ScoreboardService::BaseScraper::ScraperError => e
    # Don't log pre-game errors - they're expected when game hasn't started
    return if e.message.include?("pre-game")

    ActivityLog.create!(
      action: "scrape_error",
      record: game,
      record_type: "Game",
      metadata: { error: e.message, url: game.score_url }.to_json
    )
  end
end
