class ColorsController < ApplicationController
  before_action :set_color, only: [:edit, :update, :destroy]

  def new
    @color = Color.new
    @color.team_id = params[:team_id] if params[:team_id]
  end

  def create
    @color = Color.new(color_params)

    if @color.save
      respond_to do |format|
        format.turbo_stream do
          @color.team.reload
        end
        format.html { redirect_to team_path(@color.team), notice: "Color was successfully created." }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @color.update(color_params)
      respond_to do |format|
        format.turbo_stream do
          @color.team.reload
        end
        format.html { redirect_to team_path(@color.team), notice: "Color was successfully updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    team = @color.team
    @color.destroy
    respond_to do |format|
      format.turbo_stream { @team = team }
      format.html { redirect_to team_path(team), notice: "Color was successfully deleted." }
    end
  end

  private

  def set_color
    @color = Color.find(params[:id])
  end

  def color_params
    params.require(:color).permit(:team_id, :name, :hex, :primary)
  end
end
