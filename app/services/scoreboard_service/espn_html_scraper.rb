module ScoreboardService
  # ESPN HTML scraper - fallback for when the JSON API is unavailable.
  #
  # NOTE: ESPN uses obfuscated CSS classes on all its pages to prevent scraping.
  # We must be extremely context-dependent when scraping - use position-based
  # selectors (like nth-child) rather than class names, since the class names
  # change regularly.
  class EspnHtmlScraper
    LINESCORE_CSS_PATH = "div.next-gen-gamecast table"
    STATUS_CSS_PATH = "div.Gamestrip__Container"
    LINESCORE_CSS_INDEX = 0
    LINESCORE_SUB_CSS_PATH = "tbody tr"
    LINESCORE_CELL_CSS_PATH = "td"
    LINESCORE_START_CELL = 1
    LINESCORE_END_CELL = -2

    HTTP_TIMEOUT = 15

    def self.scrape_score(url)
      response = fetch_url(url)
      doc = parse_html(response.body)

      linescore = doc.css(LINESCORE_CSS_PATH)[LINESCORE_CSS_INDEX]
      raise ScoreboardService::ScraperError, "No linescore found in the response HTML" if linescore.nil?

      lines = linescore.css(LINESCORE_SUB_CSS_PATH)
      range = LINESCORE_START_CELL..LINESCORE_END_CELL

      away_cells = lines[0]&.css(LINESCORE_CELL_CSS_PATH)&.slice(range) || []
      home_cells = lines[1]&.css(LINESCORE_CELL_CSS_PATH)&.slice(range) || []

      raise ScoreboardService::ScraperError, "No linescore data available yet (pre-game)" if away_cells.empty? || home_cells.empty?

      {
        away: away_cells.map { |p| p.text.strip.empty? ? -1 : p.text.strip.to_i },
        home: home_cells.map { |p| p.text.strip.empty? ? -1 : p.text.strip.to_i },
        final: detect_game_status(doc) == :final
      }
    end

    def self.detect_game_status(doc)
      status_text = doc.css(STATUS_CSS_PATH).text
      raise ScoreboardService::ScraperError, "No Gamestrip found in the response HTML" if status_text.blank?
      return :final if status_text.include?("Final")
      :in_progress
    end

    def self.fetch_url(url)
      response = HTTParty.get(url, timeout: HTTP_TIMEOUT)
      raise ScoreboardService::ScraperError, "The URL returned no response" if response.body.nil? || response.body.empty?

      unless response.success?
        error_class = response.code >= 500 ? ScoreboardService::TransientError : ScoreboardService::ScraperError
        raise error_class, "HTTP #{response.code} from #{URI.parse(url).host}"
      end

      response
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise ScoreboardService::TransientError, "Timeout fetching #{URI.parse(url).host}: #{e.message}"
    rescue SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET => e
      raise ScoreboardService::TransientError, "Network error fetching #{URI.parse(url).host}: #{e.message}"
    end

    def self.parse_html(body)
      Nokogiri::HTML(body)
    rescue => e
      raise ScoreboardService::ScraperError, "HTML parse error: #{e.message}"
    end

    private_class_method :fetch_url, :parse_html, :detect_game_status
  end
end
