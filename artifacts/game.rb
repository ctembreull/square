class Game < ApplicationRecord
  after_initialize puts "woo"

  attr_reader :game_map

  GAME_PLAYERS  = 100
  SHUFFLE_TIMES = 99

  belongs_to :event
  belongs_to :league
  belongs_to :home_team, class_name: "Team"
  belongs_to :away_team, class_name: "Team"
  has_many :scores

  validates :date, presence: true
  validates :grid, presence: true
  validates :period_prize, presence: true, numericality: { only_integer: true }
  validates :final_prize, presence: true, numericality: { only_integer: true }

  scope :future, -> { where("date > ?", Date.today) }
  scope :today, -> { where("date = ?", Date.today) }
  scope :past, -> { where("date < ?", Date.today) }
  scope :earliest_first, -> { order(date: :asc) }
  scope :latest_first, -> { order(date: :desc) }

  scope :featuring, ->(team) { where("away_team_id = ?", team).or(where("home_team_id = ?", team)) }

  def build_map
    return unless @game_map.nil?
    players = Player.all.load
    @game_map = grid.split(';').map do |square|
      k, v = square.split(':')
      [ k, players.find(v) ]
    end.to_h
  end

  def get_player_for_square(ah)
    build_map if @game_map.nil?
    @game_map[ah]
  end

  def get_player_for_score(a: 0, h: 0)
    get_player_for_square("a" + a.to_s + "h" + h.to_s)
  end

  def get_score_hash
    score_hash = {}
    for i in 1..league.periods do
      score_hash[i] = scores.where(period: i)[0] || Score.new(non_scoring: (league.quarters_score_as_halves && i % 2 == 1))
      if i == league.periods
        score_hash[i].prize = final_prize
      else
        score_hash[i].prize = period_prize
      end
    end
    score_hash
  end

  def get_period_word
    case league.periods
    when 2
        "Half"
    when 4
        "Quarter"
    when 9
        "Inning"
    else
        "Period"
    end
  end

  def build_pasteable_grid
    build_map if @game_map.nil?
    pasteable = ""

    for a in 0..9
      line = ""
      for h in 0..9
        addr = "a" + a.to_s + "h" + h.to_s
        line = line + @game_map[addr].display_name
        line = line + "\t" unless h == 9
      end
      pasteable = pasteable + line
      pasteable = pasteable + "\n" unless a == 9
    end
    pasteable
  end

  def short_display_string
    away_team.location_display_string + " @ " + home_team.location_display_string
  end

  def title_display_string
    return title + ":" unless title.empty?
    ""
  end

  def create_scores
    ScoreboardService::ScoreScraper.call(self)
  end

  def mock_scores
    ScoreboardService::ScoreScraper.test(self)
  end

  private
    def build_grid
      return unless self.grid.nil? # Don't build a new grid if we've already got one.

      chances = []
      vectors = []

      # Build chances array with active players
      Player.active.each do |player|
        player.chances.times { chances.push(player.id) }
      end

      # Augment chances array with (100 - length) randomly chosen charities if length < 100
      if chances.length < GAME_PLAYERS
        charity_slots = GAME_PLAYERS - chances.length
        charities = Player.charities
        charity_slots.times do
          chances.push charities.sample.id
        end
      end

      # Randomize the chances array. Thoroughly.
      SHUFFLE_TIMES.times do
        chances.shuffle!
      end

      # Serialize the chances array as aXhY:PlayerId;...
      for a in 0..9
        for h in 0..9
          vectors.push "a#{a}h#{h}:#{chances.shift}"
        end
      end

      # And set it
      self.grid = vectors.join(";")
    end
end
