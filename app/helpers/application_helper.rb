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

  # Returns the timestamp when the Docker image was built (when compiled CSS was frozen)
  # Returns nil if no timestamp file exists (development without Docker)
  def deploy_timestamp
    return @deploy_timestamp if defined?(@deploy_timestamp)

    timestamp_file = Rails.root.join("DEPLOY_TIMESTAMP")
    @deploy_timestamp = if timestamp_file.exist?
      Time.parse(timestamp_file.read.strip).utc
    end
  end

  # Generates inline CSS for styles not in compiled CSS
  # Includes: runtime-created styles (not from YAML) and YAML styles edited after deploy
  def runtime_inline_styles
    return nil unless deploy_timestamp

    # Find styles that need inlining:
    # - runtime_style: true (created via UI, not in compiled CSS)
    # - updated_at > deploy_timestamp (YAML style edited after compilation)
    new_styles = Style.includes(:team).where(
      "runtime_style = ? OR updated_at > ?", true, deploy_timestamp
    )
    return nil if new_styles.empty?

    # Generate CSS rules using the same class names as compiled CSS
    css_rules = new_styles.map do |style|
      class_name = style.scss_class_name
      css_with_important = add_important_to_css(style.css)
      ".#{class_name} { #{css_with_important} }"
    end

    css_rules.join("\n")
  end

  private

  # Add !important to background-color and color properties to override Falcon theme
  # Same logic as TeamStylesheetService#add_important_to_css
  def add_important_to_css(css)
    css.gsub(/\b(background-color|color):\s*([^;]+);/) do |match|
      prop, value = $1, $2.strip
      if value.end_with?("!important")
        match
      else
        "#{prop}: #{value} !important;"
      end
    end
  end
end
