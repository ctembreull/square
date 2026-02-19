module ScoreboardService
  class ScraperError < StandardError; end
  class TransientError < ScraperError; end
end
