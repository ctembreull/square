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
    prefer_css_page_size: false,
    # Wait for all resources (stylesheets, fonts) to load before generating PDF
    wait_until: "networkidle0"
  }

  # Docker/production: Chromium needs --no-sandbox since container provides isolation
  if Rails.env.production? || ENV["PUPPETEER_EXECUTABLE_PATH"].present?
    config.options[:launch_args] = ["--no-sandbox", "--disable-setuid-sandbox"]
  end
end
