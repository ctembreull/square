class GamesController < ApplicationController
  before_action :set_game, only: [ :show, :edit, :update, :destroy, :swap_teams ]


  def show
  end

  def new
    @game = Game.new(event_id: params[:event_id])
    @game.period_prize = Game::DEFAULT_PERIOD_PRIZE
    @game.final_prize = Game::DEFAULT_FINAL_PRIZE
  end

  def edit
  end

  def create
    @game = Game.new(game_params)

    if @game.save
      redirect_to @game, notice: "Game was successfully created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @game.update(game_params)
      redirect_to @game, notice: "Game was successfully updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @game.destroy
      redirect_to @game.event, notice: "Event was successfully deleted"
    else
      redirect_to @game.event, alert: @game.errors.full_messages.to_sentence
    end
  end

  def swap_teams
    @game.update!(
      home_team_id: @game.away_team_id,
      away_team_id: @game.home_team_id,
      home_style: @game.away_style,
      away_style: @game.home_style
    )
    redirect_to @game, notice: "Teams swapped successfully"
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end

  def game_params
    params.require(:game).permit(:event_id, :title, :local_date, :local_time, :local_timezone,
        :league_id, :home_team_id, :home_style, :away_team_id, :away_style,
        :grid, :periods, :period_prize, :final_prize, :score_url, :broadcast_network)
  end
end
