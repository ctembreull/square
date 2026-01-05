module ScoreboardService
  class BaseScraper
    # Constants relating to how data is scraped from our sports-reference urls
    LINESCORE_CSS_PATH = 'table.linescore'
    LINESCORE_CSS_INDEX = 0
    LINESCORE_SUB_CSS_PATH = 'tbody tr'
    LINESCORE_CELL_CSS_PATH = 'td'
    LINESCORE_START_CELL = 2
    LINESCORE_END_CELL = -2

    def self.scrape_score(url)
      # Extract the linescore table fron the html of the url specified
      # TODO: add error handling around this, especially around the HTTParty get call
      raw_html = HTTParty.get(url)
      raise ScraperError, "The URL returned no response" if raw_html.nil?

      doc = Nokogiri::HTML(raw_html)
      linescore = doc.css(self::LINESCORE_CSS_PATH)[self::LINESCORE_CSS_INDEX]
      raise ScraperError, "No linescore found in the response HTML" if linescore.nil?

      # The away team is always the first row of the table body; home is second
      lines = linescore.css(self::LINESCORE_SUB_CSS_PATH)

      # Extract the per-period scores as an array of integers
      # this range expression *should* capture all period scores, but not the final
      range = self::LINESCORE_START_CELL..self::LINESCORE_END_CELL
      return {
        away: lines[0].css(self::LINESCORE_CELL_CSS_PATH)[range].map { |p| p.text.strip.empty? ? -1 : p.text.strip.to_i },
        home: lines[1].css(self::LINESCORE_CELL_CSS_PATH)[range].map { |p| p.text.strip.empty? ? -1 : p.text.strip.to_i }
      }
    end

    class ScraperError < StandardError; end
  end
end
