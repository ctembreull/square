class Color < ApplicationRecord
  belongs_to :team

  validates :name, presence: true
  validates :hex, presence: true, format: { with: /\A#?[0-9a-fA-F]{6}\z/, message: "must be a valid 6-digit hex color" }

  scope :ordered, -> { order(primary: :desc, name: :asc) }

  before_save :normalize_hex
  after_save :regenerate_team_stylesheet
  after_destroy :regenerate_team_stylesheet

  def css_hex
    "##{hex}"
  end

  private

  def normalize_hex
    self.hex = hex.delete("#").upcase if hex.present?
  end

  def regenerate_team_stylesheet
    TeamStylesheetService.generate_for(team)
  end
end
