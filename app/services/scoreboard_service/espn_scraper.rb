module ScoreboardService
  # ESPN uses a unified format for most of its boxscore/gamecast pages, so this scraper
  # should theoretically work on any of them.
  #
  # NOTE: ESPN uses obfuscated CSS classes on all its pages to prevent scraping.
  # We must be extremely context-dependent when scraping - use position-based
  # selectors (like nth-child) rather than class names, since the class names
  # change regularly.
  class EspnScraper < BaseScraper
    LINESCORE_CSS_PATH = "div.next-gen-gamecast table"
    STATUS_CSS_PATH = "div.Gamestrip__Container"
    LINESCORE_CSS_INDEX = 0
    LINESCORE_SUB_CSS_PATH = "tbody tr"
    LINESCORE_CELL_CSS_PATH = "td"
    LINESCORE_START_CELL = 1
    LINESCORE_END_CELL = -2

    def self.scrape_score(score_url)
      super(score_url)
    end

    def self.detect_game_status(doc)
      status_text = doc.css(self::STATUS_CSS_PATH).text
      raise ScraperError, "No Gamestrip found in the response HTML" if status_text.nil?
      return :final if status_text.include?("Final")
      :in_progress
    end
  end
end
