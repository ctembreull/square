class LeaguesController < ApplicationController
  before_action :set_league, only: [:show, :edit, :update, :destroy, :teams]

  def index
    @leagues = League.all.order(:sport, :name)
  end

  def show
    @conferences = @league.conferences
                          .includes(teams: :styles)
                          .alphabetical
  end

  # GET /leagues/:id/teams.json
  def teams
    @teams = @league.teams.alphabetical.distinct
    event = Event.find_by(id: params[:event_id])
    render json: {
      sport: @league.sport,
      teams: @teams.map { |t|
        {
          id: t.id,
          display_name: t.display_name(league: @league),
          last_used: t.last_game_date(event: event)&.strftime("%Y-%m-%d")
        }
      }
    }
  end

  def new
    @league = League.new
  end

  def create
    @league = League.new(league_params)

    if @league.save
      redirect_to leagues_path, notice: "League was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @league.update(league_params)
      redirect_to leagues_path, notice: "League was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @league.destroy
    redirect_to leagues_path, notice: "League was successfully deleted."
  end

  private

  def set_league
    @league = League.find(params[:id])
  end

  def league_params
    params.require(:league).permit(:name, :abbr, :sport, :gender, :level, :periods, :quarters_score_as_halves, :espn_slug)
  end
end
