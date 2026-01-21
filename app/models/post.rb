class Post < ApplicationRecord
  belongs_to :event
  belongs_to :user
  has_rich_text :body

  validates :event, presence: true
  validates :user, presence: true
  validates :title, presence: true

  # Order by most recent first
  scope :recent, -> { order(created_at: :desc) }
end
