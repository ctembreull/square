module ScoreboardService
  # ESPN JSON API scraper - primary score source.
  #
  # Uses ESPN's undocumented summary API which returns structured JSON with
  # period-by-period linescores, game status, and competitor data. Far more
  # reliable than HTML scraping since it doesn't depend on CSS selectors.
  #
  # Endpoint: https://site.api.espn.com/apis/site/v2/sports/{sport}/{league}/summary?event={gameId}
  class EspnApiScraper
    HTTP_TIMEOUT = 15

    # Takes a Game object (needs league.espn_slug + score_url to build API URL).
    # Returns { away: [int, ...], home: [int, ...], final: bool } matching
    # the same format as the HTML scrapers.
    def self.scrape_score(game)
      api_url = game.get_espn_api_summary_url
      data = fetch_json(api_url)
      parse_linescore(data)
    end

    def self.fetch_json(url)
      response = HTTParty.get(url, timeout: HTTP_TIMEOUT)

      raise ScoreboardService::ScraperError, "ESPN API returned empty response" if response.body.nil? || response.body.empty?

      unless response.success?
        error_class = response.code >= 500 ? ScoreboardService::TransientError : ScoreboardService::ScraperError
        raise error_class, "ESPN API HTTP #{response.code}"
      end

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise ScoreboardService::ScraperError, "ESPN API returned invalid JSON: #{e.message}"
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise ScoreboardService::TransientError, "ESPN API timeout: #{e.message}"
    rescue SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET => e
      raise ScoreboardService::TransientError, "ESPN API network error: #{e.message}"
    end

    def self.parse_linescore(data)
      competition = data.dig("header", "competitions", 0)
      raise ScoreboardService::ScraperError, "No competition data in ESPN API response" unless competition

      status = competition.dig("status", "type")
      state = status&.dig("state")

      # Pre-game: no linescores yet
      return { away: [], home: [], final: false } if state == "pre"

      competitors = competition["competitors"]
      raise ScoreboardService::ScraperError, "No competitors in ESPN API response" if competitors.nil? || competitors.length < 2

      away_comp = competitors.find { |c| c["homeAway"] == "away" }
      home_comp = competitors.find { |c| c["homeAway"] == "home" }
      raise ScoreboardService::ScraperError, "Cannot identify home/away teams in ESPN API response" unless away_comp && home_comp

      {
        away: extract_period_scores(away_comp),
        home: extract_period_scores(home_comp),
        final: status&.dig("completed") == true
      }
    end

    def self.extract_period_scores(competitor)
      linescores = competitor["linescores"]
      return [] if linescores.nil? || linescores.empty?

      linescores.map { |ls| ls["displayValue"].to_i }
    end

    private_class_method :fetch_json, :parse_linescore, :extract_period_scores
  end
end
