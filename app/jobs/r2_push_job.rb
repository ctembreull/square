class R2PushJob < ApplicationJob
  queue_as :default

  def perform
    # Only run in production on Fly.io
    return unless Rails.env.production? && ENV["FLY_APP_NAME"].present?

    # Run the rake task
    Rake::Task["r2:push"].invoke

    # Log completion (ActivityLog can be added when that feature is implemented)
    Rails.logger.info "[R2Backup] Daily backup completed at #{Time.current}"
  end
end
