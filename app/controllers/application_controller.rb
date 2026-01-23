require "pagy"

class ApplicationController < ActionController::Base
  include Pagy::Method

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Use timezone from cookie for all requests
  around_action :set_timezone

  # Require admin for all actions by default
  before_action :require_admin

  helper_method :current_timezone, :current_user, :logged_in?, :admin?, :show_admin_tools?

  private

  def set_timezone(&block)
    Time.use_zone(current_timezone, &block)
  end

  def current_timezone
    cookies[:timezone] || "Eastern Time (US & Canada)"
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def admin?
    current_user&.admin?
  end

  def show_admin_tools?
    admin? && session[:show_admin_tools] != false
  end

  def require_admin
    unless admin?
      flash[:alert] = "You must be logged in as an admin to access this page"
      redirect_to login_path
    end
  end
end
