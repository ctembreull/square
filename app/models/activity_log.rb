class ActivityLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :record, polymorphic: true, optional: true

  validates :action, presence: true
  validates :record_type, presence: true

  scope :recent, -> { order(created_at: :desc).limit(100) }
  scope :for_record, ->(record) { where(record_type: record.class.name, record_id: record.id) }
  scope :errors, -> { where(action: "scrape_error") }
end
