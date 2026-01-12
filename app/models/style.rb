class Style < ApplicationRecord
  belongs_to :team

  validates :name, presence: true
  validates :css, presence: true

  scope :ordered, -> { order(default: :desc, name: :asc) }

  after_save :ensure_single_default
  after_save :regenerate_team_stylesheet
  after_destroy :regenerate_team_stylesheet

  private

  def ensure_single_default
    if default? && saved_change_to_default?
      team.styles.where.not(id: id).update_all(default: false)
    end
  end

  def regenerate_team_stylesheet
    TeamStylesheetService.generate_for(team)
  end
end
