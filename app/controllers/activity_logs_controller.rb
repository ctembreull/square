class ActivityLogsController < ApplicationController
  before_action :require_admin

  def index
    scope = ActivityLog.includes(:user).recent

    # Apply filters
    scope = scope.by_action(params[:action_filter]) if params[:action_filter].present?
    scope = scope.by_record_type(params[:record_type_filter]) if params[:record_type_filter].present?
    scope = scope.by_level(params[:level_filter]) if params[:level_filter].present?

    if params[:user_filter].present?
      if params[:user_filter] == "system"
        scope = scope.where(user_id: nil)
      else
        scope = scope.where(user_id: params[:user_filter])
      end
    end

    @pagy, @activity_logs = pagy(scope, items: 25)

    # Preload polymorphic records in batch, skipping non-model types like "System"
    preloadable = @activity_logs.select { |l| l.record_id.present? && l.record_type&.safe_constantize }
    ActiveRecord::Associations::Preloader.new(records: preloadable, associations: [ :record ]).call

    # Get distinct users who have activity logs for the filter dropdown
    @users_for_filter = User.joins(:activity_logs).distinct.order(:name)
  end
end
