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
  end

  def create
    @conference = Conference.new(conference_params)

    if @conference.save
      redirect_to conferences_path, notice: "Conference was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @conference.update(conference_params)
      redirect_to conferences_path, notice: "Conference was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @conference.destroy
    redirect_to conferences_path, notice: "Conference was successfully deleted."
  end

  private

  def set_conference
    @conference = Conference.find(params[:id])
  end

  def conference_params
    params.require(:conference).permit(:name, :abbr, :league_id)
  end
end
