class ConferencesController < ApplicationController
  before_action :set_conference, only: [ :show, :edit, :update, :destroy ]

  def index
    @conferences = Conference.includes(:league).alphabetical
  end

  def show
    @affiliations = @conference.affiliations.includes(team: :styles).order("teams.location")
    # Teams at this level that don't yet have any affiliation in this league
    teams_in_league = Affiliation.where(league_id: @conference.league_id).select(:team_id)
    @available_teams = Team.where(level: @conference.league.level)
                           .where.not(id: teams_in_league)
                           .alphabetical

    # Load games involving teams from this conference, grouped by event
    team_ids = @conference.teams.pluck(:id)
    @games_by_event = Game.includes(:event, :home_team, :away_team, :league)
                          .where("home_team_id IN (?) OR away_team_id IN (?)", team_ids, team_ids)
                          .order("events.start_date DESC, games.starts_at DESC")
                          .group_by(&:event)
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
