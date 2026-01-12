class TeamStylesheetService
  STYLESHEETS_DIR = Rails.root.join("app", "assets", "stylesheets", "teams")

  def initialize(team)
    @team = team
  end

  def generate
    ensure_directory_exists
    write_stylesheet
  end

  def self.generate_for(team)
    new(team).generate
  end

  def self.generate_all
    ensure_directory_exists
    Team.includes(:colors, :styles).find_each do |team|
      new(team).generate
    end
  end

  def self.ensure_directory_exists
    FileUtils.mkdir_p(STYLESHEETS_DIR)
  end

  private

  def ensure_directory_exists
    self.class.ensure_directory_exists
  end

  def write_stylesheet
    File.write(stylesheet_path, stylesheet_content)
  end

  def stylesheet_path
    STYLESHEETS_DIR.join("_#{@team.scss_slug}.scss")
  end

  def stylesheet_content
    content = []
    content << file_header
    content << color_variables
    content << style_classes
    content << default_style_alias
    content.flatten.compact.join("\n")
  end

  def file_header
    [
      "// Team: #{@team.display_name}",
      "// Generated: #{Time.current.iso8601}",
      "// Do not edit directly - regenerate via TeamStylesheetService",
      ""
    ]
  end

  def color_variables
    return [] if @team.colors.empty?

    lines = ["// Color Variables"]
    @team.colors.ordered.each do |color|
      variable_name = color_variable_name(color)
      lines << "$#{variable_name}: ##{color.hex};"
    end
    lines << ""
    lines
  end

  def color_variable_name(color)
    color_slug = color.name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/-+$/, "")
    "#{@team.scss_prefix}-#{color_slug}"
  end

  def style_classes
    return [] if @team.styles.empty?

    lines = ["// Style Classes"]
    @team.styles.ordered.each do |style|
      class_name = style_class_name(style)
      lines << ".#{class_name} {"
      lines << "  #{style.css}"
      lines << "}"
      lines << ""
    end
    lines
  end

  def style_class_name(style)
    style_slug = style.name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/-+$/, "")
    "#{@team.scss_prefix}-#{style_slug}"
  end

  def default_style_alias
    default_style = @team.styles.find_by(default: true)
    return [] unless default_style

    default_class = "#{@team.scss_prefix}-default"
    source_class = style_class_name(default_style)

    [
      "// Default Style Alias",
      ".#{default_class} {",
      "  @extend .#{source_class};",
      "}",
      ""
    ]
  end
end
