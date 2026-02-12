class AddLevelToActivityLogs < ActiveRecord::Migration[8.1]
  def change
    add_column :activity_logs, :level, :string, default: "info", null: false
    add_index :activity_logs, :level
  end
end
