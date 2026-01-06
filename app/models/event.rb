class Event < ApplicationRecord
  # Associations
  # Using restrict_with_error prevents accidental deletion of events with games
  # This forces explicit cleanup of games first if deletion is truly needed
  has_many :games, dependent: :restrict_with_error
  has_many :posts, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :upcoming, -> { where("start_date > ?", Date.today).order(:start_date) }
  scope :current, -> { where("start_date <= ? AND end_date >= ?", Date.today, Date.today).order(:start_date) }
  scope :past, -> { where("end_date < ?", Date.today).order(start_date: :desc) }

  # Prevent deletion if games exist
  before_destroy :prevent_deletion_with_games

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "must be after the start date")
    end
  end

  def prevent_deletion_with_games
    if games.any?
      errors.add(:base, "Cannot delete event with associated games. Archive the event or delete games first.")
      throw(:abort)
    end
  end
end
