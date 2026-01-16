module ScoreboardService
  # This scraper subclass works on sports-reference.com college football and NFL box scores
  class SrCfbScraper < BaseScraper
    LINESCORE_CSS_PATH = 'table.linescore'
    LINESCORE_CSS_INDEX = 0
    LINESCORE_SUB_CSS_PATH = 'tbody tr'
    LINESCORE_CELL_CSS_PATH = 'td'
    LINESCORE_START_CELL = 2
    LINESCORE_END_CELL = -2

    def self.scrape_score(score_url)
      super(score_url)
    end
  end
end
