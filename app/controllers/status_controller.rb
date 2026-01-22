class StatusController < ApplicationController
  skip_before_action :require_admin

  def show
    render json: {
      events: Event.count,
      games: Game.count,
      leagues: League.count,
      conferences: Conference.count,
      teams: Team.count,
      colors: Color.count,
      styles: Style.count
    }
  end
end
