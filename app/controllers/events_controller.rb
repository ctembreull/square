class EventsController < ApplicationController
  def index
    @current_event = Event.active.current.first
    @past_events = Event.active.past
  end

  def show
    @event = Event.find(params[:id])
  end
end
