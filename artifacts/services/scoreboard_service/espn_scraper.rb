module ScoreboardService
  # ESPN uses a unified format for most of its boxscore/gamecast pages, so this scraper
  # should theoretically work on any of them
  class EspnScraper < BaseScraper
    LINESCORE_CSS_PATH = 'div.next-gen-gamecast table'
    LINESCORE_CSS_INDEX = 0
    LINESCORE_SUB_CSS_PATH = 'tbody tr'
    LINESCORE_CELL_CSS_PATH = 'td'
    LINESCORE_START_CELL = 1
    LINESCORE_END_CELL = -2

    def self.scrape_score(score_url)
      super(score_url)
    end
  end
end
