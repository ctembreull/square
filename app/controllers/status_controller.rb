class StatusController < ApplicationController
  skip_before_action :require_admin

  HEARTBEAT_STALE_THRESHOLD = 10.minutes

  def show
    status = {
      events: Event.count,
      games: Game.count,
      leagues: League.count,
      conferences: Conference.count,
      teams: Team.count,
      colors: Color.count,
      styles: Style.count
    }

    if Rails.env.production? && ENV["FLY_APP_NAME"].present?
      heartbeat = Rails.cache.read("queue_heartbeat")
      stale = heartbeat.nil? || heartbeat < HEARTBEAT_STALE_THRESHOLD.ago

      status[:queue_status] = stale ? "stalled" : "ok"
      status[:queue_heartbeat] = heartbeat&.iso8601

      if stale
        log_queue_stall(heartbeat)
        render json: status, status: :service_unavailable
        return
      end
    end

    render json: status
  end

  private

  def log_queue_stall(last_heartbeat)
    # Deduplicate: only log once per 30 minutes
    return if Rails.cache.read("queue_stall_alerted")

    ActivityLog.create(
      action: "queue_stalled",
      level: "warning",
      record_type: "System",
      metadata: {
        last_heartbeat: last_heartbeat&.iso8601,
        detected_at: Time.current.iso8601,
        stale_for: last_heartbeat ? "#{((Time.current - last_heartbeat) / 60).round} minutes" : "never seen"
      }.to_json
    )

    Rails.cache.write("queue_stall_alerted", true, expires_in: 30.minutes)
  end
end
