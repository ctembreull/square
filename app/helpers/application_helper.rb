module ApplicationHelper
  # Environment detection for visual indicators
  # Uses APP_ENV if set, otherwise falls back to Rails.env
  # Set APP_ENV=staging in Docker, APP_ENV=production on Fly.io
  def app_environment
    ENV.fetch("APP_ENV", Rails.env)
  end

  def environment_label
    case app_environment
    when "development" then "DEV"
    when "staging" then "STAGING"
    when "production" then nil  # No label needed for production
    else app_environment.upcase
    end
  end

  def environment_color
    case app_environment
    when "development" then "#28a745"  # Green
    when "staging" then "#ffc107"      # Yellow/amber
    when "production" then nil         # Default/no change
    else "#6c757d"                     # Gray for unknown
    end
  end

  def page_title(title = nil)
    base = title || content_for(:title) || "Square"
    label = environment_label
    label ? "[#{label}] #{base}" : base
  end
end
