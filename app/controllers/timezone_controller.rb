class TimezoneController < ApplicationController
  skip_before_action :require_admin

  def update
    timezone = params[:timezone]

    if ActiveSupport::TimeZone[timezone]
      cookies[:timezone] = { value: timezone, expires: 1.year.from_now }
    end

    redirect_back fallback_location: root_path
  end
end
