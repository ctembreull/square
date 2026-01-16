require "pagy"

class ApplicationController < ActionController::Base
  include Pagy::Method

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Use timezone from cookie for all requests
  around_action :set_timezone

  helper_method :current_timezone

  private

  def set_timezone(&block)
    Time.use_zone(current_timezone, &block)
  end

  def current_timezone
    cookies[:timezone] || "Eastern Time (US & Canada)"
  end
end
