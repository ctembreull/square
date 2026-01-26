class BannerGameSelector < ApplicationService
  Result = Struct.new(:rows, :headers, keyword_init: true)

  def initialize(event)
    @event = event
    @upcoming = event.games.upcoming.earliest_first.to_a
    @in_progress = event.games.in_progress.earliest_first.to_a
    @completed = event.games.completed.latest_first.to_a
  end

  def call
    case @in_progress.count
    when 0 then layout_zero_in_progress
    when 1 then layout_one_in_progress
    when 2 then layout_two_in_progress
    when 3 then layout_three_in_progress
    else        layout_four_plus_in_progress
    end
  end

  private

  # 0 in-progress: 1 row with upcoming, completed #1, completed #2
  # Fallback rules apply when games are missing
  def layout_zero_in_progress
    if @upcoming.any? && @completed.count >= 2
      # Default: upcoming + 2 completed
      Result.new(
        rows: [ [ @upcoming[0], @completed[0], @completed[1] ] ],
        headers: [ "Upcoming", "Recent Games", nil ]
      )
    elsif @upcoming.empty? && @completed.count >= 3
      # No upcoming (tournament over): 3 completed
      Result.new(
        rows: [ [ @completed[0], @completed[1], @completed[2] ] ],
        headers: [ "Recent Games", nil, nil ]
      )
    elsif @completed.count == 1 && @upcoming.count >= 2
      # Only 1 completed: 2 upcoming + 1 completed
      Result.new(
        rows: [ [ @upcoming[0], @upcoming[1], @completed[0] ] ],
        headers: [ "Upcoming", nil, "Recent Games" ]
      )
    elsif @completed.empty? && @upcoming.count >= 3
      # No completed (early event): 3 upcoming
      Result.new(
        rows: [ [ @upcoming[0], @upcoming[1], @upcoming[2] ] ],
        headers: [ "Upcoming", nil, nil ]
      )
    else
      # Fallback: fill with whatever we have (no duplicates)
      all_games = (@upcoming + @completed).uniq
      Result.new(
        rows: [ [ all_games[0], all_games[1], all_games[2] ] ],
        headers: [ "Games", nil, nil ]
      )
    end
  end

  # 1 in-progress: 1 row with upcoming, in-progress, completed
  def layout_one_in_progress
    Result.new(
      rows: [ [ @upcoming[0], @in_progress[0], @completed[0] ] ],
      headers: [ "Upcoming", "Playing Now", "Recent Games" ]
    )
  end

  # 2 in-progress: 2 rows of 3
  def layout_two_in_progress
    Result.new(
      rows: [
        [ @upcoming[0], @in_progress[0], @completed[0] ],
        [ @upcoming[1], @in_progress[1], @completed[1] ]
      ],
      headers: [ "Upcoming", "Playing Now", "Recent Games" ]
    )
  end

  # 3 in-progress: 1 row with just the 3 in-progress games
  def layout_three_in_progress
    Result.new(
      rows: [ [ @in_progress[0], @in_progress[1], @in_progress[2] ] ],
      headers: [ "Playing Now", nil, nil ]
    )
  end

  # 4+ in-progress: 2 rows
  # Row 1: in-progress #1, #2, #3
  # Row 2: nil, in-progress #4, nil (centered)
  def layout_four_plus_in_progress
    Result.new(
      rows: [
        [ @in_progress[0], @in_progress[1], @in_progress[2] ],
        [ nil, @in_progress[3], nil ]
      ],
      headers: [ "Playing Now", nil, nil ]
    )
  end
end
