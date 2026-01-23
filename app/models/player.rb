class Player < ApplicationRecord
  # STI subclasses: Single, Individual, Family, Charity

  # Family relationships (self-referential)
  belongs_to :family, class_name: "Family", optional: true
  has_many :members, class_name: "Player", foreign_key: :family_id

  # Validations
  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :chances, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate :total_chances_within_limit, if: -> { active? && !is_a?(Charity) }

  # Scopes for STI types
  scope :humans, -> { where.not(type: "Charity") }
  scope :families, -> { where(type: "Family") }
  scope :individuals, -> { where(type: "Individual") }
  scope :singles, -> { where(type: "Single") }
  scope :charities, -> { where(type: "Charity") }

  # Activity scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :without_family, -> { where(family_id: nil) }

  # Email recipients: active Families and Singles with email addresses
  # (Individuals belong to Families, Charities are placeholders)
  scope :email_recipients, -> {
    where(type: %w[Family Single])
      .where(active: true)
      .where.not(email: [ nil, "" ])
  }

  # Class method for grid validation (only counts human players, not charities)
  def self.total_active_chances
    humans.active.sum(:chances)
  end

  # Display name with fallback
  def display_name_or_name
    display_name.presence || name
  end

  private

  def total_chances_within_limit
    other_chances = Player.humans.active.where.not(id: id).sum(:chances)
    total = other_chances + (chances || 0)

    if total > 100
      errors.add(:chances, "would bring total active chances to #{total}, which exceeds 100")
    end
  end
end
