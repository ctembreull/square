class Event < ApplicationRecord
  # Associations
  # Using restrict_with_error prevents accidental deletion of events with games
  # This forces explicit cleanup of games first if deletion is truly needed
  has_many :games, dependent: :restrict_with_error
  has_many :posts, dependent: :destroy
  has_one_attached :pdf

  # Validations
  validates :title, presence: true
  validates :start_date, presence: true
  validate :end_date_after_start_date, if: -> { end_date.present? }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :in_progress, -> { where("start_date <= ? AND (end_date IS NULL OR end_date >= ?)", Date.today, Date.today) }
  scope :upcoming, -> { where("start_date > ?", Date.today) }
  scope :completed, -> { where("end_date IS NOT NULL AND end_date < ?", Date.today) }

  # Prevent deletion if games exist
  before_destroy :prevent_deletion_with_games

  # Status helpers
  def status
    if start_date > Date.today
      :upcoming
    elsif end_date.present? && end_date < Date.today
      :completed
    else
      :in_progress
    end
  end

  def upcoming?
    status == :upcoming
  end

  def in_progress?
    status == :in_progress
  end

  def completed?
    status == :completed
  end

  def end_event!
    update(end_date: Date.today)
  end

  # PDF helpers
  def pdf_stale?
    return true unless pdf.attached?
    pdf_created = pdf.blob.created_at
    # PDF is stale if any game or score was updated after PDF was generated
    games.where("updated_at > ?", pdf_created).exists? ||
      Score.joins(:game).where(games: { event_id: id }).where("scores.updated_at > ?", pdf_created).exists?
  end

  def pdf_fresh?
    pdf.attached? && !pdf_stale?
  end

  def pdf_filename
    "#{title.parameterize}-games.pdf"
  end

  private

  def end_date_after_start_date
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
