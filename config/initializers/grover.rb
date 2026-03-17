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
    # Wait for resources to load before generating PDF (networkidle2 allows 2
    # outstanding connections, more reliable than networkidle0 on same-host setups)
    wait_until: "networkidle2",
    # Navigation timeout in ms (default 30s is tight on constrained Fly.io machines)
    timeout: 60_000
  }

  # Docker/production: Chromium needs --no-sandbox since container provides isolation
  if Rails.env.production? || ENV["PUPPETEER_EXECUTABLE_PATH"].present?
    config.options[:launch_args] = [
      "--no-sandbox",
      "--disable-setuid-sandbox",
      "--disable-dev-shm-usage"
    ]
  end
end
