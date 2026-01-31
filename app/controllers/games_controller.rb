class GamesController < ApplicationController
  skip_before_action :require_admin, only: [:show]
  before_action :set_game, only: [ :show, :edit, :update, :destroy, :swap_teams, :refresh_scores, :manual_scores ]


  def show
    @highlight_period = params[:highlight_period].to_i if params[:highlight_period].present?
  end

  def new
    @game = Game.new(event_id: params[:event_id])
    @game.period_prize = Game::DEFAULT_PERIOD_PRIZE
    @game.final_prize = Game::DEFAULT_FINAL_PRIZE
    @game.local_timezone = default_timezone_for_form
  end

  def edit
    # Apply default timezone if the game doesn't have one set
    @game.local_timezone ||= default_timezone_for_form
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

  def refresh_scores
    is_final = ScoreboardService::ScoreScraper.call(@game)
    @game.complete! if is_final
    redirect_to @game, notice: "Scores refreshed successfully"
  rescue ScoreboardService::ScoreScraper::ScraperError => e
    redirect_to @game, alert: "Failed to refresh scores: #{e.message}"
  end

  def fetch_espn_data
    espn_api_url = params[:espn_api_url]
    return render json: { error: "No ESPN API URL provided" }, status: :bad_request if espn_api_url.blank?

    begin
      response = HTTParty.get(espn_api_url, timeout: 10)
      return render json: { error: "ESPN API request failed" }, status: :bad_gateway unless response.success?

      data = response.parsed_response
      competition = data.dig("header", "competitions", 0)
      return render json: { error: "No competition data found" }, status: :not_found unless competition

      # Determine league from ESPN API URL first - we need its level for team lookup
      league = determine_league_from_espn_url(espn_api_url)

      competitors = competition["competitors"] || []
      home_competitor = competitors.find { |c| c["homeAway"] == "home" }
      away_competitor = competitors.find { |c| c["homeAway"] == "away" }

      home_espn_id = home_competitor&.dig("team", "id")
      away_espn_id = away_competitor&.dig("team", "id")

      # ESPN IDs are only unique within a sport, so filter by level (college vs pro)
      team_scope = league ? Team.where(level: league.level) : Team
      home_team = team_scope.find_by(espn_id: home_espn_id) if home_espn_id
      away_team = team_scope.find_by(espn_id: away_espn_id) if away_espn_id

      # Parse date - ESPN returns UTC, convert to user's timezone
      game_date_utc = competition["date"]
      local_date = nil
      local_time = nil
      local_timezone = default_timezone_for_form

      if game_date_utc.present?
        utc_time = Time.parse(game_date_utc)
        tz = TZInfo::Timezone.get(local_timezone)
        local_time_obj = tz.utc_to_local(utc_time.utc)
        local_date = local_time_obj.strftime("%Y-%m-%d")
        local_time = local_time_obj.strftime("%H:%M")
      end

      # Extract broadcast networks
      broadcasts = competition["broadcasts"] || []
      broadcast_network = broadcasts.map { |b| b.dig("media", "shortName") }.compact.join(" / ")

      render json: {
        league_id: league&.id,
        league_name: league&.name,
        home_team_id: home_team&.id,
        home_team_name: home_team&.display_name || home_competitor&.dig("team", "displayName"),
        away_team_id: away_team&.id,
        away_team_name: away_team&.display_name || away_competitor&.dig("team", "displayName"),
        local_date: local_date,
        local_time: local_time,
        local_timezone: local_timezone,
        broadcast_network: broadcast_network.presence,
        home_espn_id: home_espn_id,
        away_espn_id: away_espn_id
      }
    rescue StandardError => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  def manual_scores
    periods = @game.league.periods
    away_scores = params[:away_scores].values.map { |v| v.blank? ? nil : v.to_i }
    home_scores = params[:home_scores].values.map { |v| v.blank? ? nil : v.to_i }
    mark_final = params[:mark_final] == "1"
    overtime = params[:overtime] == "1"

    progressive_away = 0
    progressive_home = 0

    (0..(periods - 1)).each do |i|
      period_number = i + 1
      away_score = away_scores[i]
      home_score = home_scores[i]

      # Skip periods without scores
      next if away_score.nil? || home_score.nil?

      progressive_away += away_score
      progressive_home += home_score

      # Destroy existing score for this period and create new one
      @game.scores.where(period: period_number).destroy_all

      prize = period_number == periods ? @game.final_prize : @game.period_prize
      winner_address = "a#{progressive_away % 10}h#{progressive_home % 10}"
      winner = @game.get_player_for_square(winner_address)

      score = Score.new(
        game: @game,
        period: period_number,
        complete: true,
        ot: period_number == periods && overtime,
        away: away_score,
        home: home_score,
        away_total: progressive_away,
        home_total: progressive_home,
        prize: prize,
        winner: winner
      )

      # Mark as non-scoring for women's basketball (Q1, Q3)
      if @game.league.quarters_score_as_halves && period_number.odd?
        score.non_scoring = true
      end

      score.save!
    end

    @game.broadcast_scores
    @game.start! if @game.upcoming?
    @game.complete! if mark_final

    redirect_to @game, notice: "Scores updated successfully"
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end

  def game_params
    params.require(:game).permit(:event_id, :title, :local_date, :local_time, :local_timezone,
        :league_id, :home_team_id, :home_style, :away_team_id, :away_style,
        :grid, :periods, :period_prize, :final_prize, :score_url, :espn_api_url, :broadcast_network)
  end

  def default_timezone_for_form
    # Convert Rails timezone name from cookie to IANA identifier for the form select
    if cookies[:timezone].present?
      tz = ActiveSupport::TimeZone[cookies[:timezone]]
      iana_id = tz&.tzinfo&.name
      # Return the IANA id if it's in our supported list, otherwise fall back to Pacific
      return iana_id if Game::TIMEZONES.any? { |_, id| id == iana_id }
    end
    "America/Los_Angeles" # Pacific time as default
  end

  def determine_league_from_espn_url(url)
    # Map ESPN API URL sport paths to our league abbreviations
    mappings = {
      "basketball/mens-college-basketball" => "MBB",
      "basketball/womens-college-basketball" => "WBB",
      "football/nfl" => "NFL",
      "football/college-football" => "FBS" # Default to FBS for college football
    }

    mappings.each do |path, abbr|
      return League.find_by(abbr: abbr) if url.include?(path)
    end

    nil
  end
end
