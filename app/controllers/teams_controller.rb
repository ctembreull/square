class TeamsController < ApplicationController
  before_action :set_team, only: [ :show, :edit, :update, :destroy, :styles ]

  def index
    @q = Team.ransack(params[:q])
    @q.sorts = "display_location asc" if @q.sorts.empty?
    @pagy, @teams = pagy(:offset, @q.result.includes(:affiliations, :colors, :styles))
  end

  def show
  end

  # GET /teams/:id/styles.json
  def styles
    @styles = @team.styles.ordered
    render json: @styles.map { |s| { id: s.id, name: s.name, scss_class_name: s.scss_class_name, default: s.default } }
  end

  def new
    @team = Team.new
  end

  def create
    @team = Team.new(team_params)

    if @team.save
      redirect_to @team, notice: "Team was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @team.update(team_params)
      redirect_to @team, notice: "Team was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @team.destroy
    redirect_to teams_path, notice: "Team was successfully deleted."
  end

  private

  def set_team
    @team = Team.find(params[:id])
  end

  def team_params
    params.require(:team).permit(:name, :location, :display_location, :abbr, :level, :womens_name, :brand_info)
  end
end
