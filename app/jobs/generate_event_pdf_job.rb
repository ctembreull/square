class GenerateEventPdfJob < ApplicationJob
  queue_as :default

  def perform(event_id)
    event = Event.find_by(id: event_id)
    return unless event

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

    # Broadcast that PDF is ready
    Turbo::StreamsChannel.broadcast_replace_to(
      event,
      target: "event_pdf_status",
      partial: "events/pdf_status",
      locals: { event: event }
    )
  rescue StandardError => e
    Rails.logger.error "[GenerateEventPdfJob] Failed to generate PDF for event #{event_id}: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")

    # Broadcast error state
    Turbo::StreamsChannel.broadcast_replace_to(
      event,
      target: "event_pdf_status",
      partial: "events/pdf_status",
      locals: { event: event, error: e.message }
    )
  end
end
