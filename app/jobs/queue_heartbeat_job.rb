class QueueHeartbeatJob < ApplicationJob
  queue_as :default

  def perform
    # Only run in production on Fly.io
    return unless Rails.env.production? && ENV["FLY_APP_NAME"].present?

    Rails.cache.write("queue_heartbeat", Time.current)
  end
end
