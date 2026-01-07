class League < ApplicationRecord
  has_many :conferences, dependent: :destroy
  has_many :games, dependent: :restrict_with_error
  has_many :affiliations, dependent: :destroy

  enum :sport, { football: "football", basketball: "basketball" }, validate: true

  validates :name, presence: true
  validates :periods, presence: true, numericality: { only_integer: true, greater_than: 0 }

  scope :by_sport, ->(sport) { where(sport: sport) }
  scope :by_gender, ->(gender) { where(gender: gender) }
end
