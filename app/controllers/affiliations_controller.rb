class AffiliationsController < ApplicationController
  before_action :set_affiliation, only: [:show, :edit, :update, :destroy]

  def index
    @affiliations = Affiliation.includes(:team, :league, :conference, :division).all
  end

  def show
  end

  def new
    @affiliation = Affiliation.new
    @affiliation.team_id = params[:team_id] if params[:team_id]
    @affiliation.league_id = params[:league_id] if params[:league_id]
    @affiliation.conference_id = params[:conference_id] if params[:conference_id]
    @affiliation.division_id = params[:division_id] if params[:division_id]
  end

  def create
    @affiliation = Affiliation.new(affiliation_params)

    if @affiliation.save
      redirect_to affiliations_path, notice: "Affiliation was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @affiliation.update(affiliation_params)
      redirect_to affiliations_path, notice: "Affiliation was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @affiliation.destroy
    redirect_to affiliations_path, notice: "Affiliation was successfully deleted."
  end

  private

  def set_affiliation
    @affiliation = Affiliation.find(params[:id])
  end

  def affiliation_params
    params.require(:affiliation).permit(:team_id, :league_id, :conference_id, :division_id)
  end
end
