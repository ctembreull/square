class GenerateEventPdfJob < ApplicationJob
  queue_as :default
  retry_on ActiveRecord::StatementTimeout, wait: 5.seconds, attempts: 3

  def perform(event_id, user_id = nil)
    event = Event.find_by(id: event_id)
    return unless event

    user = User.find_by(id: user_id) if user_id
    Rails.logger.info "[GenerateEventPdfJob] Starting PDF generation for event #{event_id}"

    # Eager load associations to avoid N+1 queries during PDF generation
    games_scope = event.games.includes(:home_team, :away_team, :league, scores: :winner)
    upcoming_games = games_scope.upcoming.earliest_first
    completed_games = games_scope.completed.latest_first

    # Preload all players once for grid lookups
    all_players = Player.all.index_by(&:id)

    # Render HTML using ApplicationController to get access to helpers
    controller = ApplicationController.new
    controller.request = ActionDispatch::Request.new({})

    html = controller.render_to_string(
      template: "events/pdf",
      layout: "pdf",
      locals: {
        event: event,
        upcoming_games: upcoming_games,
        completed_games: completed_games,
        players_by_id: all_players
      }
    )

    # Use internal port for Puppeteer to fetch stylesheets
    # In production on Fly.io, use port 8080 (the app's internal port)
    internal_port = Rails.env.production? ? 8080 : 3000
    pdf_data = Grover.new(html, display_url: "http://localhost:#{internal_port}").to_pdf

    # Attach PDF to event (replaces any existing attachment)
    event.pdf.attach(
      io: StringIO.new(pdf_data),
      filename: event.pdf_filename,
      content_type: "application/pdf"
    )

    Rails.logger.info "[GenerateEventPdfJob] PDF generation complete for event #{event_id}"

    # Log PDF generation (with retry for database locks)
    log_with_retry do
      ActivityLog.create!(
        action: "pdf_generated",
        record: event,
        user: user,
        metadata: {
          event_title: event.title,
          game_count: event.games.count,
          file_size: pdf_data.bytesize
        }.to_json
      )
    end

    # Broadcast that PDF is ready (to event show page)
    Turbo::StreamsChannel.broadcast_replace_to(
      event,
      target: "event_pdf_status",
      partial: "events/pdf_status",
      locals: { event: event }
    )

    # Broadcast to email sender page
    Turbo::StreamsChannel.broadcast_replace_to(
      event,
      target: "email_sender_pdf_status",
      partial: "events/pdf_status_email_sender",
      locals: { event: event }
    )
  rescue StandardError => e
    Rails.logger.error "[GenerateEventPdfJob] Failed to generate PDF for event #{event_id}: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")

    # Log PDF generation failure (with retry for database locks)
    log_with_retry do
      ActivityLog.create!(
        action: "pdf_generation_failed",
        record: event,
        user: user,
        level: "error",
        metadata: {
          event_title: event.title,
          error_class: e.class.name,
          error_message: e.message,
          backtrace: e.backtrace.first(5)
        }.to_json
      )
    end

    # Broadcast error state (to event show page)
    Turbo::StreamsChannel.broadcast_replace_to(
      event,
      target: "event_pdf_status",
      partial: "events/pdf_status",
      locals: { event: event, error: e.message }
    )

    # Broadcast error to email sender page
    Turbo::StreamsChannel.broadcast_replace_to(
      event,
      target: "email_sender_pdf_status",
      partial: "events/pdf_status_email_sender",
      locals: { event: event, error: e.message }
    )
  end

  private

  def log_with_retry(max_attempts: 3, wait: 0.5)
    attempts = 0
    begin
      attempts += 1
      yield
    rescue ActiveRecord::StatementTimeout, SQLite3::BusyException => e
      if attempts < max_attempts
        sleep(wait * attempts)  # Exponential backoff
        retry
      else
        Rails.logger.error "[GenerateEventPdfJob] Failed to log after #{attempts} attempts: #{e.message}"
        # Don't re-raise - we don't want logging failures to fail the job
      end
    end
  end
end
