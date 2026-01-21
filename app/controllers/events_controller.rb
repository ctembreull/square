class EventsController < ApplicationController
  skip_before_action :require_admin, only: [ :index, :show, :display, :home ]
  before_action :set_event, only: [ :show, :edit, :update, :destroy, :activate, :deactivate, :end_event, :winners, :display ]

  def home
    current_event = Event.active.current.first
    if current_event
      redirect_to event_path(current_event)
    else
      redirect_to events_path
    end
  end

  def index
    @active_events = Event.active.order(start_date: :desc)
    @inactive_events = Event.inactive.order(start_date: :desc)
  end

  def show
    @banner_rows = BannerGameSelector.call(@event)
  end

  def display
    @banner_rows = BannerGameSelector.call(@event)
  end

  def new
    @event = Event.new(active: true)
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

  def activate
    @event.update(active: true)
    redirect_to events_path, notice: "#{@event.title} has been activated."
  end

  def deactivate
    @event.update(active: false)
    redirect_to events_path, notice: "#{@event.title} has been deactivated."
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

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :start_date, :end_date, :active)
  end
end
