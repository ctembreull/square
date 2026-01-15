class Player < ApplicationRecord
  # STI subclasses: Single, Individual, Family, Charity

  # Family relationships (self-referential)
  belongs_to :family, class_name: "Family", optional: true
  has_many :members, class_name: "Player", foreign_key: :family_id

  # Validations
  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :chances, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

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

  # Class method for grid validation (only counts human players, not charities)
  def self.total_active_chances
    humans.active.sum(:chances)
  end

  # Display name with fallback
  def display_name_or_name
    display_name.presence || name
  end
end
