class StylesController < ApplicationController
  before_action :set_style, only: [:edit, :update, :destroy]

  def new
    @style = Style.new
    @style.team_id = params[:team_id] if params[:team_id]
    @team = @style.team || Team.find(params[:team_id])
  end

  def create
    @style = Style.new(style_params)
    @style.runtime_style = true  # UI-created styles need inline CSS until next deploy
    @team = @style.team

    if @style.save
      respond_to do |format|
        format.turbo_stream do
          @style.team.reload
        end
        format.html { redirect_to team_path(@style.team), notice: "Style was successfully created." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @team = @style.team
  end

  def update
    @team = @style.team

    if @style.update(style_params)
      respond_to do |format|
        format.turbo_stream do
          @style.team.reload
        end
        format.html { redirect_to team_path(@style.team), notice: "Style was successfully updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    team = @style.team
    @style.destroy
    respond_to do |format|
      format.turbo_stream { @team = team }
      format.html { redirect_to team_path(team), notice: "Style was successfully deleted." }
    end
  end

  private

  def set_style
    @style = Style.find(params[:id])
  end

  def style_params
    params.require(:style).permit(:team_id, :name, :css, :default)
  end
end
