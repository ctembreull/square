module ScoreboardService
  class ScoreScraper < ApplicationService
    # Constants relating to how data is scraped from our sports-reference urls
    LINESCORE_CSS_PATH = 'table.linescore'
    LINESCORE_START_CELL = 2

    def initialize(game)
      raise ScraperError, "No score URL set for game <#{game.id}>" if game.score_url.blank? || game.score_url.nil?
      @game = game;
      @periods = game.league.periods
    end

    def call
      process_score(scrape_score)
    end

    def test
      fake_process_score(scrape_score)
    end

    def scrape_score
      raw_linescore = scrape_by_url

      # Check to make sure that we have the same number of raw periods in both the home and away sections
      # of the linescore
      raise ScraperError, "Mismatched period lengths" if raw_linescore[:away].length != raw_linescore[:home].length

      # Process overtimes (if any) and return; this will give us the proper format for our game
      # display pages (we compress any overtime scoring into the final-period score and note it
      # as n/OT). This ultimately returns a pair of n-element arrays, where n is the number of
      # periods in a standard league game.
      return {
        away: process_overtime(raw_linescore[:away]),
        home: process_overtime(raw_linescore[:home]),
        overtime: raw_linescore[:home].length > @periods
      }
    end

    def scrape_by_url
      if !@game.score_url.match("espn.com").nil?
        # Attempt to process with the ESPN scraper
        return ScoreboardService::EspnScraper.scrape_score(@game.score_url)
      elsif !@game.score_url.match("reference.com").nil?
        # Attempt to process with the Sports-Reference CFB/NFL scraper
        return ScoreboardService::SrCfbScraper.scrape_score(@game.score_url)
      else
        # Attempt to process with the base scraper (configured for general sports-reference use)
        return ScoreboardService::BaseScraper.scrape_score(@game.score_url)
      end
    end

    def process_overtime(line)
      regulation = line[0..(@periods-1)]
      overtime   = line[@periods..-1]

      if (!overtime.empty?)
        # compress the overtime periods into the final regulation period score
        overtime.each do |s|
          regulation[@periods - 1] += s
        end
      end

      return regulation
    end

    def process_score(linescore)
      progressive_score = { away: 0, home: 0 }
      for i in 0..(@periods - 1)
        period_number = i + 1
        away_score = linescore[:away][i]
        home_score = linescore[:home][i]

        # The scraper puts a -1 as the score in for every period that hasn't been played yet.
        # If we see that happen, skip that period and don't attempt to create a Score object for it.
        next if away_score == -1 || home_score == -1

        progressive_score[:away] += away_score
        progressive_score[:home] += home_score

        ## IMPORTANT
        #  We can't have duplicate scores for any game period. They mess things up. There can only be one
        #  canonical score per period per game. So, we must destroy any score for the requested period for
        #  the game, and create a new one from the information we have. This will be useful for if and when
        #  there's a scoring change or something goes wrong with creating any individual Score object.
        @game.scores.where(period: period_number).destroy_all

        # Now, whether or not there was a score to destroy for this period, create a new score object
        # TODO: Add some pretty heavy error handling around this to alert the user that scores were not
        # created. Probably should log this entire process in its own special logfile for easy debugging.
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

        if @game.league.quarters_score_as_halves && period_number % 2 == 1
          period_score.non_scoring = true
        end

        # This should raise an error if the score object fails to save
        period_score.save!
      end
    end

    def fake_process_score(linescore)
      progressive_score = { away: 0, home: 0 }
      scores_by_period = []

      for i in 0..(@periods - 1)
        period_number = i + 1
        away_score = linescore[:away][i]
        home_score = linescore[:home][i]

        # The scraper puts a -1 as the score in for every period that hasn't been played yet.
        # If we see that happen, skip that period and don't attempt to create a Score object for it.
        next if away_score == -1 || home_score == -1

        progressive_score[:away] += away_score
        progressive_score[:home] += home_score

        # Now, whether or not there was a score to destroy for this period, create a new score object
        # TODO: Add some pretty heavy error handling around this to alert the user that scores were not
        #   created. Probably should log this entire process in its own special logfile for easy debugging.
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
          winner: process_winner(progressive_score).display_name
        }

        if @game.league.quarters_score_as_halves && period_number % 2 == 1
          period_score.non_scoring = true
        end

        # This should raise an error if the score object fails to save
        scores_by_period[i] = period_score
      end

      return scores_by_period
    end

    def process_winner(progressive_score)
      winner_address = "a" + (progressive_score[:away] % 10).to_s + "h" + (progressive_score[:home] % 10).to_s
      return @game.get_player_for_square(winner_address)
    end

    def process_prize(period)
      return (period == @game.league.periods) ? @game.final_prize : @game.period_prize
    end

    class ScrapeError < StandardError; end
  end
end
