class EventsController < ApplicationController
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
  end

  def display
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
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:title, :start_date, :end_date, :active)
  end
end
