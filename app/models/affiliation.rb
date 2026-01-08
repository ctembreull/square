class Affiliation < ApplicationRecord
  belongs_to :league
  belongs_to :conference
  belongs_to :division
  belongs_to :team

  validates :league_id, presence: true
  validates :conference_id, presence: true
  validates :division_id, presence: true
  validates :team_id, presence: true
  validates :league_id, uniqueness: { scope: [:conference_id, :division_id, :team_id] }

  validate :conference_belongs_to_league
  validate :division_belongs_to_conference

  scope :by_team, ->(team) { where(team: team) }
  scope :by_league, ->(league) { where(league: league) }
  scope :by_conference, ->(conference) { where(conference: conference) }
  scope :by_division, ->(division) { where(division: division) }

  private

  def conference_belongs_to_league
    return unless conference && league
    errors.add(:conference, "must belong to the selected league") unless conference.league_id == league_id
  end

  def division_belongs_to_conference
    return unless division && conference
    errors.add(:division, "must belong to the selected conference") unless division.conference_id == conference_id
  end
end
