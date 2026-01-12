class Color < ApplicationRecord
  belongs_to :team

  validates :name, presence: true
  validates :hex, presence: true, format: { with: /\A#?[0-9a-fA-F]{6}\z/, message: "must be a valid 6-digit hex color" }

  scope :ordered, -> { order(primary: :desc, name: :asc) }

  before_save :normalize_hex

  def css_hex
    "##{hex}"
  end

  private

  def normalize_hex
    self.hex = hex.delete("#").upcase if hex.present?
  end
end
