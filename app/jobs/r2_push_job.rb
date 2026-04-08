class R2PushJob < ApplicationJob
  queue_as :default

  def perform
    # Only run in production on Fly.io
    unless Rails.env.production? && ENV["FLY_APP_NAME"].present?
      Rails.logger.info "[R2Backup] Skipped: not production or FLY_APP_NAME not set"
      return
    end

    Rails.logger.info "[R2Backup] Starting daily backup..."

    # Rake isn't loaded in the SolidQueue worker context —
    # it's only auto-available when booted via `rake` or `rails` CLI.
    # Guard: only load tasks once per process. Repeated load_tasks calls
    # re-register task bodies, causing duplicate execution (see #50).
    require "rake"
    Rails.application.load_tasks unless Rake::Task.task_defined?("r2:push")

    # Reenable the task chain — Rake marks tasks as "already invoked"
    # in long-lived processes, so subsequent runs silently no-op
    %w[structure:export seeds:export players:export affiliations:export r2:push].each do |task|
      Rake::Task[task].reenable
    end

    Rake::Task["r2:push"].invoke

    Rails.logger.info "[R2Backup] Daily backup completed at #{Time.current}"
  rescue => e
    Rails.logger.error "[R2Backup] FAILED: #{e.class}: #{e.message}"
    Rails.logger.error "[R2Backup] #{e.backtrace&.first(5)&.join("\n")}"

    ActivityLog.create!(
      action: "r2_sync",
      record_type: "System",
      level: "error",
      metadata: {
        error: e.class.name,
        message: e.message,
        backtrace: e.backtrace&.first(5)
      }.to_json
    )
  end
end
