class Conference < ApplicationRecord
  belongs_to :league
  has_many :divisions, dependent: :destroy
  has_many :affiliations, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :league_id }
  validates :abbr, presence: true, uniqueness: { scope: :league_id }
  validates :league_id, presence: true

  scope :by_league, ->(league) { where(league: league) }
  scope :alphabetical, -> { order(:name) }
end
