class Style < ApplicationRecord
  belongs_to :team

  validates :name, presence: true
  validates :css, presence: true

  scope :ordered, -> { order(default: :desc, name: :asc) }
  scope :default, -> { where(default: true) }

  after_save :ensure_single_default
  after_save :regenerate_team_stylesheet
  after_destroy :regenerate_team_stylesheet

  def scss_slug
    name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/-+$/, "")
  end

  def scss_class_name
    [ team.scss_slug, scss_slug ].join("-")
  end

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
