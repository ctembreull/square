class EventsController < ApplicationController
  skip_before_action :require_admin, only: [ :index, :show, :display, :home ]
  before_action :set_event, only: [ :show, :edit, :update, :destroy, :end_event, :winners, :winners_worksheet, :display, :pdf, :generate_pdf ]

  def home
    current_event = Event.in_progress.first
    if current_event
      redirect_to event_path(current_event)
    else
      redirect_to events_path
    end
  end

  def index
    @current_events = Event.in_progress.order(start_date: :asc)
    @upcoming_events = Event.upcoming.order(start_date: :asc)
    @completed_events = Event.completed.order(end_date: :desc)
  end

  def show
    # Eager load all games with associations to avoid N+1 queries
    @games = @event.games.includes(:home_team, :away_team, :league, :scores).to_a
    @banner_rows = BannerGameSelector.call(@event, games: @games)

    # Partition games by status in Ruby (avoids multiple DB queries)
    @games_in_progress = @games.select(&:in_progress?).sort_by(&:starts_at)
    @games_upcoming = @games.select(&:upcoming?).sort_by(&:starts_at)
    @games_completed = @games.select(&:completed?).sort_by { |g| -g.starts_at.to_i }

    # Preload posts (sorted by recent)
    @posts = @event.posts.order(created_at: :desc).to_a
  end

  def display
    @banner_rows = BannerGameSelector.call(@event)
  end

  def new
    @event = Event.new
  end

  def edit
  end

  def create
    @event = Event.new(event_params)

    if @event.save
      redirect_to events_path, notice: "Event was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @event.update(event_params)
      redirect_to events_path, notice: "Event was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @event.destroy
      redirect_to events_path, notice: "Event was successfully deleted."
    else
      redirect_to events_path, alert: @event.errors.full_messages.to_sentence
    end
  end

  def end_event
    @event.end_event!
    redirect_to events_path, notice: "#{@event.title} has been ended."
  end

  def winners
    @winners = helpers.aggregate_winners(@event).group_by { |w| w[:family] }
    @charities = @winners.delete("charity") || []
    @families = Player.where(id: @winners.keys).index_by(&:id)
    @total_awarded = (@winners.values.flatten + @charities).sum { |w| w[:total] }
  end

  def winners_worksheet
    @winners = helpers.aggregate_winners(@event).group_by { |w| w[:family] }
    @charities = @winners.delete("charity") || []
    @families = Player.where(id: @winners.keys).index_by(&:id)
    @total_awarded = (@winners.values.flatten + @charities).sum { |w| w[:total] }
  end

  def pdf
    # Serve cached PDF if available and fresh
    if @event.pdf_fresh?
      redirect_to rails_blob_path(@event.pdf, disposition: "attachment")
    elsif @event.pdf.attached?
      # PDF exists but is stale - serve it but note it's outdated
      redirect_to rails_blob_path(@event.pdf, disposition: "attachment")
    else
      # No PDF cached - generate synchronously (fallback for dev/testing)
      generate_pdf_sync
    end
  end

  def generate_pdf
    GenerateEventPdfJob.perform_later(@event.id)
    respond_to do |format|
      format.html { redirect_to @event, notice: "PDF generation started. This may take a minute." }
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          "event_pdf_status",
          partial: "events/pdf_status",
          locals: { event: @event, generating: true }
        )
      }
    end
  end

  private

  def generate_pdf_sync
    # Eager load associations to avoid N+1 queries during PDF generation
    games_scope = @event.games.includes(:home_team, :away_team, :league, scores: :winner)
    @upcoming_games = games_scope.upcoming.earliest_first
    @completed_games = games_scope.completed.latest_first
    @all_players = Player.all.index_by(&:id)

    html = render_to_string(
      template: "events/pdf",
      layout: "pdf",
      locals: {
        event: @event,
        upcoming_games: @upcoming_games,
        completed_games: @completed_games,
        players_by_id: @all_players
      }
    )

    internal_port = Rails.env.production? ? 8080 : request.port
    pdf_data = Grover.new(html, display_url: "http://localhost:#{internal_port}").to_pdf

    send_data pdf_data,
      filename: @event.pdf_filename,
      type: "application/pdf",
      disposition: "attachment"
  end

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :start_date, :end_date)
  end
end
