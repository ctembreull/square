# frozen_string_literal: true

Grover.configure do |config|
  config.options = {
    format: "Letter",
    landscape: true,
    margin: {
      top: "0.25in",
      bottom: "0.25in",
      left: "0.5in",
      right: "0.5in"
    },
    print_background: true,
    prefer_css_page_size: false
  }
end
