class ChangeEventsEndDateOptional < ActiveRecord::Migration[8.1]
  def change
    change_column_null :events, :end_date, true
  end
end
