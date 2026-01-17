class RefreshActiveGamesJob < ApplicationJob
  queue_as :default

  def perform
    Game.in_progress.find_each do |game|
      RefreshGameScoresJob.perform_later(game.id)
    end
  end
end
