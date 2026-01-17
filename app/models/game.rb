class Game < ApplicationRecord
  include ActionView::RecordIdentifier

  DEFAULT_PERIOD_PRIZE = 25
  DEFAULT_FINAL_PRIZE = 50
  STATUSES = %w[upcoming in_progress completed].freeze

  TIMEZONES = [
    [ "Eastern", "America/New_York" ],
    [ "Central", "America/Chicago" ],
    [ "Mountain", "America/Denver" ],
    [ "Arizona", "America/Phoenix" ],
    [ "Pacific", "America/Los_Angeles" ],
    [ "Alaska", "America/Anchorage" ],
    [ "Hawaii", "Pacific/Honolulu" ]
  ].freeze

  GAME_PLAYERS = 100
  SHUFFLE_TIMES = 99

  DEFAULT_TIMEZONE = "America/Los Angeles"

  after_initialize :build_grid, if: :new_record?
  after_save :schedule_score_refresh, if: :should_schedule_refresh?
  attr_reader :game_map
  attr_writer :local_date, :local_time

  def local_timezone=(value)
    @local_timezone = value
    self.timezone = value if value.present?
  end

  before_validation :combine_datetime_fields

  # Virtual attribute readers - extract from starts_at for edit forms
  def local_date
    @local_date || (starts_at&.in_time_zone(local_timezone || DEFAULT_TIMEZONE)&.to_date)
  end

  def local_time
    return @local_time if @local_time
    return nil unless starts_at

    starts_at.in_time_zone(local_timezone || DEFAULT_TIMEZONE).strftime("%H:%M")
  end

  def local_timezone
    @local_timezone || timezone || DEFAULT_TIMEZONE
  end

  belongs_to :event
  belongs_to :league
  belongs_to :home_team, class_name: "Team"
  belongs_to :away_team, class_name: "Team"

  has_many :scores, dependent: :destroy

  validates :event, presence: true
  validates :league, presence: true
  validates :home_team, presence: true
  validates :away_team, presence: true
  validates :score_url, presence: true
  validates :period_prize, presence: true, numericality: { only_integer: true }
  validates :final_prize, presence: true, numericality: { only_integer: true }

  scope :upcoming, -> { where("starts_at > ?", Time.current) }
  scope :today, -> { where(starts_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :past, -> { where("starts_at < ?", Time.current) }
  scope :earliest_first, -> { order(starts_at: :asc) }
  scope :latest_first, -> { order(starts_at: :desc) }
  scope :featuring, ->(team) { where("away_team_id = ?", team).or(where("home_team_id = ?", team)) }
  scope :in_progress, -> { where(status: "in_progress") }
  scope :completed, -> { where(status: "completed") }

  def build_map
    # Assumes grid =~ "a0h0:<player_id>;<a0h1>:<player_id>..."
    return unless @game_map.nil?
    players = Player.all.load
    @game_map = grid.split(";").map do |square|
      k, v = square.split(":")
      [ k, players.find(v) ]
    end.to_h
  end

  def get_player_for_square(ah)
    build_map
    @game_map[ah]
  end

  def get_player_for_score(a: 0, h: 0)
    get_player_for_square("a" + a.to_s + "h" + h.to_s)
  end

  # Returns starts_at in the specified timezone (defaults to Eastern)
  def starts_at_in_zone(zone = "America/New_York")
    return nil unless starts_at
    starts_at.in_time_zone(zone)
  end

  # Status helpers
  def upcoming?
    status == "upcoming"
  end

  def in_progress?
    status == "in_progress"
  end

  def completed?
    status == "completed"
  end

  def start!
    update!(status: "in_progress")
  end

  def complete!
    update!(status: "completed")
  end

  # Broadcast score updates to connected clients via Turbo Streams
  def broadcast_scores
    reload # Ensure we have fresh scores association
    Turbo::StreamsChannel.broadcast_update_to(
      self, "scores",
      target: dom_id(self, :scores),
      partial: "games/components/grid_scores",
      locals: { game: self }
    )
    Turbo::StreamsChannel.broadcast_update_to(
      self, "scores",
      target: dom_id(self, :winners),
      partial: "games/components/grid_winners",
      locals: { game: self }
    )
  end

  private

  def combine_datetime_fields
    return if local_date.blank? || local_time.blank? || local_timezone.blank?

    tz = ActiveSupport::TimeZone[local_timezone]
    return unless tz

    date = local_date.is_a?(String) ? Date.parse(local_date) : local_date
    time = local_time.is_a?(String) ? Time.parse(local_time) : local_time

    self.starts_at = tz.local(date.year, date.month, date.day, time.hour, time.min).utc
  end

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

  def should_schedule_refresh?
    saved_change_to_starts_at? && starts_at.present? && starts_at > Time.current && upcoming?
  end

  def schedule_score_refresh
    cancel_pending_refresh_jobs
    RefreshGameScoresJob.set(wait_until: starts_at).perform_later(id)
  end

  def cancel_pending_refresh_jobs
    # Find and cancel any existing scheduled RefreshGameScoresJob for this game
    SolidQueue::Job.where(class_name: "RefreshGameScoresJob")
                   .where("arguments LIKE ?", "%\"arguments\":[#{id}]%")
                   .where(finished_at: nil)
                   .find_each(&:destroy)
  end
end
