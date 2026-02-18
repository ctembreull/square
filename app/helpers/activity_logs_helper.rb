module ActivityLogsHelper
  def log_badge_color(level)
    case level
    when "error" then "danger"
    when "warning" then "warning"
    when "info" then "info"
    else "secondary"
    end
  end

  def format_activity_metadata(metadata_json)
    return "" if metadata_json.blank?
    metadata = JSON.parse(metadata_json)
    content_tag(:pre, JSON.pretty_generate(metadata), class: "mb-0 p-2 bg-100 rounded fs-10")
  rescue JSON::ParserError
    content_tag(:small, "Invalid JSON", class: "text-muted")
  end

  def activity_record_link(log)
    return content_tag(:span, log.record_type, class: "text-muted") unless log.record_id.present? && log.record_type&.safe_constantize

    case log.record
    when Game
      link_to log.record.title, log.record
    when Event
      link_to log.record.title, log.record
    when Post
      link_to log.record.title, log.record
    else
      content_tag(:span, "#{log.record_type} ##{log.record_id}")
    end
  end
end
