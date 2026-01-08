class ConferencesController < ApplicationController
  before_action :set_conference, only: [:show, :edit, :update, :destroy]

  def index
    @conferences = Conference.includes(:league).alphabetical
  end

  def show
    @divisions = @conference.divisions.by_order
  end

  def new
    @conference = Conference.new
    @conference.league_id = params[:league_id] if params[:league_id]
  end

  def create
    @conference = Conference.new(conference_params)

    if @conference.save
      redirect_to league_path(@conference.league), notice: "Conference was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @conference.update(conference_params)
      redirect_to league_path(@conference.league), notice: "Conference was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    league = @conference.league
    @conference.destroy
    redirect_to league_path(league), notice: "Conference was successfully deleted."
  end

  private

  def set_conference
    @conference = Conference.find(params[:id])
  end

  def conference_params
    params.require(:conference).permit(:name, :display_name, :abbr, :league_id)
  end
end
