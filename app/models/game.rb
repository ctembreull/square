class Game < ApplicationRecord
  belongs_to :event
  belongs_to :league
  belongs_to :home_team, class_name: "Team"
  belongs_to :away_team, class_name: "Team"

  has_many :scores, dependent: :destroy

  validates :event, presence: true
  validates :league, presence: true
  validates :home_team, presence: true
  validates :away_team, presence: true
end
