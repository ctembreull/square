class Post < ApplicationRecord
  belongs_to :event

  validates :event, presence: true
end
