class RefreshGameScoresJob < ApplicationJob
  queue_as :default

  # Retry transient errors (timeouts, 5xx) with backoff: ~3s, ~18s, ~83s
  retry_on ScoreboardService::TransientError,
    wait: :polynomially_longer, attempts: 3

  def perform(game_id)
    game = Game.find_by(id: game_id)
    return unless game&.score_url.present?
    return if game.completed?
    return unless valid_url?(game.score_url)

    # Transition from upcoming to in_progress when job runs at game time
    game.start! if game.upcoming?

    is_final = ScoreboardService::ScoreScraper.call(game)
    game.complete! if is_final
    Rails.logger.info "[RefreshGameScoresJob] Completed scrape for game #{game_id}, final=#{is_final}"
  rescue URI::InvalidURIError
    Rails.logger.warn "[RefreshGameScoresJob] Invalid URL for game #{game_id}: #{game&.score_url}"
  rescue ScoreboardService::ScraperError => e
    # Don't log pre-game errors - they're expected when game hasn't started
    return if e.message.include?("pre-game")

    ActivityLog.create!(
      action: "scrape_error",
      record: game,
      level: "error",
      metadata: { error: e.class.name, message: e.message, url: game.score_url }.to_json
    )
  rescue StandardError => e
    # Catch unexpected errors so they hit the activity log instead of failing silently
    ActivityLog.create!(
      action: "scrape_error",
      record: game,
      level: "error",
      metadata: {
        error: e.class.name,
        message: e.message,
        url: game&.score_url,
        backtrace: e.backtrace&.first(5)
      }.to_json
    )
  end

  private

  def valid_url?(url)
    uri = URI.parse(url)
    uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    false
  end
end
