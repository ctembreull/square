module ScoreboardService
  class BaseScraper
    # Constants relating to how data is scraped from our sports-reference urls
    LINESCORE_CSS_PATH = "table.linescore"
    STATUS_CSS_PATH = "table.linescore"
    LINESCORE_CSS_INDEX = 0
    LINESCORE_SUB_CSS_PATH = "tbody tr"
    LINESCORE_CELL_CSS_PATH = "td"
    LINESCORE_START_CELL = 2
    LINESCORE_END_CELL = -2

    HTTP_TIMEOUT = 15 # seconds for both connect and read

    def self.scrape_score(url)
      response = fetch_url(url)
      doc = parse_html(response.body)

      linescore = doc.css(self::LINESCORE_CSS_PATH)[self::LINESCORE_CSS_INDEX]
      raise ScraperError, "No linescore found in the response HTML" if linescore.nil?

      # The away team is always the first row of the table body; home is second
      lines = linescore.css(self::LINESCORE_SUB_CSS_PATH)

      # Extract the per-period scores as an array of integers
      # this range expression *should* capture all period scores, but not the final
      range = self::LINESCORE_START_CELL..self::LINESCORE_END_CELL

      away_cells = lines[0]&.css(self::LINESCORE_CELL_CSS_PATH)&.slice(range) || []
      home_cells = lines[1]&.css(self::LINESCORE_CELL_CSS_PATH)&.slice(range) || []

      # If we didn't find any period cells, the linescore doesn't exist yet (pre-game)
      raise ScraperError, "No linescore data available yet (pre-game)" if away_cells.empty? || home_cells.empty?

      {
        away: away_cells.map { |p| p.text.strip.empty? ? -1 : p.text.strip.to_i },
        home: home_cells.map { |p| p.text.strip.empty? ? -1 : p.text.strip.to_i },
        final: self.detect_game_status(doc) == :final
      }
    end

    def self.detect_game_status(doc)
      :unknown
    end

    def self.fetch_url(url)
      response = HTTParty.get(url, timeout: HTTP_TIMEOUT)
      raise ScraperError, "The URL returned no response" if response.body.nil? || response.body.empty?

      unless response.success?
        error_class = response.code >= 500 ? TransientError : ScraperError
        raise error_class, "HTTP #{response.code} from #{URI.parse(url).host}"
      end

      response
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise TransientError, "Timeout fetching #{URI.parse(url).host}: #{e.message}"
    rescue SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET => e
      raise TransientError, "Network error fetching #{URI.parse(url).host}: #{e.message}"
    end

    def self.parse_html(body)
      Nokogiri::HTML(body)
    rescue => e
      raise ScraperError, "HTML parse error: #{e.message}"
    end

    class ScraperError < StandardError; end
    class TransientError < ScraperError; end
  end
end
