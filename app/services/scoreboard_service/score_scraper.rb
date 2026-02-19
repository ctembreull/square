module ScoreboardService
  class ScraperError < StandardError; end
  class TransientError < ScraperError; end

  class ScoreScraper < ApplicationService
    def initialize(game)
      raise ScraperError, "No score URL set for game <#{game.id}>" if game.score_url.blank?
      @game = game
      @periods = game.league.periods
      @scraper_source = nil
    end

    def call
      linescore = scrape_score
      process_score(linescore)
      @game.broadcast_scores
      linescore[:final]
    end

    def test
      fake_process_score(scrape_score)
    end

    def scrape_score
      raw_linescore = scrape_by_url

      # Check to make sure that we have the same number of raw periods in both
      # the home and away sections of the linescore
      raise ScraperError, "Mismatched period lengths" if raw_linescore[:away].length != raw_linescore[:home].length

      # Process overtimes (if any) and return; this will give us the proper format
      # for our game display pages (we compress any overtime scoring into the
      # final-period score and note it as n/OT).
      {
        away: process_overtime(raw_linescore[:away]),
        home: process_overtime(raw_linescore[:home]),
        overtime: raw_linescore[:home].length > @periods,
        final: raw_linescore[:final] || false
      }
    end

    def scrape_by_url
      raise ScraperError, "Unsupported score URL: #{@game.score_url}" unless @game.score_url.match?("espn.com")

      scrape_espn
    end

    # ESPN: try JSON API first, fall back to HTML scraper
    def scrape_espn
      if @game.league.espn_slug.present?
        begin
          result = ScoreboardService::EspnApiScraper.scrape_score(@game)
          @scraper_source = "espn_api"
          result
        rescue ScoreboardService::ScraperError => e
          Rails.logger.warn "[ScoreScraper] ESPN API failed (#{e.message}), falling back to HTML for game #{@game.id}"
          @scraper_source = "espn_html_fallback"
          ScoreboardService::EspnHtmlScraper.scrape_score(@game.score_url)
        end
      else
        @scraper_source = "espn_html"
        ScoreboardService::EspnHtmlScraper.scrape_score(@game.score_url)
      end
    end

    def process_overtime(line)
      regulation = line[0..(@periods - 1)]
      overtime = line[@periods..-1]

      if overtime&.any?
        # Compress the overtime periods into the final regulation period score
        overtime.each do |s|
          regulation[@periods - 1] += s
        end
      end

      regulation
    end

    def process_score(linescore)
      # Skip if no real scores yet (ESPN shows all zeros before game starts)
      return if linescore[:away].all?(&:zero?) && linescore[:home].all?(&:zero?)

      periods_updated = []

      ActiveRecord::Base.transaction do
        progressive_score = { away: 0, home: 0 }

        (0..(@periods - 1)).each do |i|
          period_number = i + 1
          away_score = linescore[:away][i]
          home_score = linescore[:home][i]

          # The scraper puts a -1 as the score for every period that hasn't been played yet.
          # If we see that happen (or nil if array is short), skip that period.
          next if away_score.nil? || home_score.nil? || away_score == -1 || home_score == -1

          progressive_score[:away] += away_score
          progressive_score[:home] += home_score

          # We can't have duplicate scores for any game period. There can only be one
          # canonical score per period per game. So, we must destroy any existing score
          # for this period and create a new one.
          @game.scores.where(period: period_number).destroy_all

          # Create new score object
          period_score = Score.new(
            game: @game,
            period: period_number,
            ot: (i == @periods - 1) && linescore[:overtime],
            complete: true,
            away: away_score,
            home: home_score,
            away_total: progressive_score[:away],
            home_total: progressive_score[:home],
            prize: process_prize(period_number),
            winner: process_winner(progressive_score)
          )

          # Mark as non-scoring for women's basketball (Q1, Q3)
          if @game.league.quarters_score_as_halves && period_number.odd?
            period_score.non_scoring = true
          end

          period_score.save!

          # Track this period for activity log
          periods_updated << {
            period: period_number,
            away: away_score,
            home: home_score,
            away_total: progressive_score[:away],
            home_total: progressive_score[:home],
            winner_id: period_score.winner_id
          }
        end

        # Log the automated score update
        ActivityLog.create!(
          action: "score_update_automated",
          record: @game,
          metadata: {
            source: @scraper_source || "unknown",
            score_url: @game.score_url,
            periods_updated: periods_updated,
            final: linescore[:final]
          }.to_json
        )
      end
    rescue => e
      # Log transaction failure
      ActivityLog.create!(
        action: "transaction_rollback",
        record: @game,
        level: "error",
        metadata: {
          error_class: e.class.name,
          error_message: e.message,
          backtrace: e.backtrace.first(5),
          context: "automated_score_scraping"
        }.to_json
      )
      raise # Re-raise to preserve existing error handling
    end

    def fake_process_score(linescore)
      progressive_score = { away: 0, home: 0 }
      scores_by_period = []

      (0..(@periods - 1)).each do |i|
        period_number = i + 1
        away_score = linescore[:away][i]
        home_score = linescore[:home][i]

        next if away_score.nil? || home_score.nil? || away_score == -1 || home_score == -1

        progressive_score[:away] += away_score
        progressive_score[:home] += home_score

        period_score = {
          game: @game.id,
          period: period_number,
          ot: (i == @periods - 1) && linescore[:overtime],
          complete: true,
          away: away_score,
          home: home_score,
          away_total: progressive_score[:away],
          home_total: progressive_score[:home],
          prize: process_prize(period_number),
          winner: process_winner(progressive_score)&.display_name
        }

        if @game.league.quarters_score_as_halves && period_number.odd?
          period_score[:non_scoring] = true
        end

        scores_by_period[i] = period_score
      end

      scores_by_period.compact
    end

    def process_winner(progressive_score)
      winner_address = "a#{progressive_score[:away] % 10}h#{progressive_score[:home] % 10}"
      @game.get_player_for_square(winner_address)
    end

    def process_prize(period)
      period == @game.league.periods ? @game.final_prize : @game.period_prize
    end

  end
end
