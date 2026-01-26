class AffiliationsController < ApplicationController
  before_action :set_affiliation, only: [:show, :edit, :update, :destroy]

  def index
    @affiliations = Affiliation.includes(:team, :league, :conference).all
  end

  def show
  end

  def new
    @affiliation = Affiliation.new
    @affiliation.team_id = params[:team_id] if params[:team_id]
    @affiliation.league_id = params[:league_id] if params[:league_id]
    @affiliation.conference_id = params[:conference_id] if params[:conference_id]
    set_available_leagues
  end

  def create
    @affiliation = Affiliation.new(affiliation_params)

    if @affiliation.save
      respond_to do |format|
        format.turbo_stream do
          @affiliation.team.reload
          @from_conference = request.referer&.include?("/conferences/")
          @conference = @affiliation.conference if @from_conference
        end
        format.html do
          if request.referer&.include?("/conferences/")
            redirect_to conference_path(@affiliation.conference), notice: "Team added to conference."
          else
            redirect_to team_path(@affiliation.team), notice: "Affiliation was successfully created."
          end
        end
      end
    else
      if request.referer&.include?("/conferences/") && @affiliation.conference_id.present?
        redirect_to conference_path(@affiliation.conference_id), alert: @affiliation.errors.full_messages.join(", ")
      else
        set_available_leagues
        render :new, status: :unprocessable_entity
      end
    end
  end

  def edit
  end

  def update
    if @affiliation.update(affiliation_params)
      respond_to do |format|
        format.turbo_stream do
          @affiliation.team.reload
        end
        format.html { redirect_to team_path(@affiliation.team), notice: "Affiliation was successfully updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    team = @affiliation.team
    conference = @affiliation.conference
    @affiliation.destroy
    respond_to do |format|
      format.turbo_stream do
        @team = team
        @from_conference = request.referer&.include?("/conferences/")
        @conference = conference if @from_conference
      end
      format.html do
        if request.referer&.include?("/conferences/")
          redirect_to conference_path(conference), notice: "Team removed from conference."
        else
          redirect_to team_path(team), notice: "Affiliation was successfully deleted."
        end
      end
    end
  end

  private

  def set_affiliation
    @affiliation = Affiliation.find(params[:id])
  end

  def affiliation_params
    params.require(:affiliation).permit(:team_id, :league_id, :conference_id)
  end

  def set_available_leagues
    if @affiliation.team_id.present?
      affiliated_league_ids = Affiliation.where(team_id: @affiliation.team_id).pluck(:league_id)
      @available_leagues = League.where.not(id: affiliated_league_ids).order(:name)
    else
      @available_leagues = League.order(:name)
    end
  end
end
