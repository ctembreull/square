class ActivityLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :record, polymorphic: true, optional: true

  validates :action, presence: true
  validates :record_type, presence: true

  # Ordering scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest_first, -> { order(created_at: :asc) }

  # Filtering scopes
  scope :for_record, ->(record) { where(record_type: record.class.name, record_id: record.id) }
  scope :by_action, ->(action) { where(action: action) if action.present? }
  scope :by_record_type, ->(type) { where(record_type: type) if type.present? }
  scope :by_level, ->(level) { where(level: level) if level.present? }

  # Level-specific scopes
  scope :errors, -> { where(level: "error") }
  scope :warnings, -> { where(level: "warning") }
  scope :info, -> { where(level: "info") }

  # Helper methods
  def error?
    level == "error"
  end

  def warning?
    level == "warning"
  end

  def info?
    level == "info"
  end

  def parsed_metadata
    return {} if metadata.blank?
    JSON.parse(metadata)
  rescue JSON::ParserError
    {}
  end
end
