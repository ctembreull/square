class Division < ApplicationRecord
  belongs_to :conference
  has_many :affiliations, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :conference_id }
  validates :abbr, presence: true
  validates :conference_id, presence: true
  validates :order, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :by_conference, ->(conference) { where(conference: conference) }
  scope :by_order, -> { order(:order) }
end
