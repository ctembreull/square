class RefreshActiveGamesJob < ApplicationJob
  queue_as :default

  def perform
    # Process games that are in progress
    Game.in_progress.find_each do |game|
      RefreshGameScoresJob.perform_later(game.id)
    end

    # Also process games that should have started but haven't been transitioned yet
    Game.where(status: "upcoming").where("starts_at <= ?", Time.current).find_each do |game|
      RefreshGameScoresJob.perform_later(game.id)
    end
  end
end
