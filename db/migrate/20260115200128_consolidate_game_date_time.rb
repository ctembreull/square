class ConsolidateGameDateTime < ActiveRecord::Migration[8.1]
  def up
    add_column :games, :starts_at, :datetime

    # Migrate existing data: combine date + time + timezone into UTC datetime
    Game.reset_column_information
    Game.find_each do |game|
      next unless game.date.present?

      time_value = game.read_attribute(:time) || Time.parse("12:00")
      tz_string = game.read_attribute(:timezone) || "America/New_York"

      begin
        tz = ActiveSupport::TimeZone[tz_string]
        local_datetime = tz.local(
          game.date.year,
          game.date.month,
          game.date.day,
          time_value.hour,
          time_value.min
        )
        game.update_column(:starts_at, local_datetime.utc)
      rescue => e
        Rails.logger.warn "Could not migrate game #{game.id}: #{e.message}"
      end
    end

    remove_column :games, :date
    remove_column :games, :time
    remove_column :games, :timezone

    add_index :games, :starts_at
  end

  def down
    add_column :games, :date, :date
    add_column :games, :time, :time
    add_column :games, :timezone, :string

    Game.reset_column_information
    Game.find_each do |game|
      next unless game.starts_at.present?

      # Default to Eastern when rolling back
      tz = ActiveSupport::TimeZone["America/New_York"]
      local_time = game.starts_at.in_time_zone(tz)

      game.update_columns(
        date: local_time.to_date,
        time: local_time.strftime("%H:%M:%S"),
        timezone: "America/New_York"
      )
    end

    remove_index :games, :starts_at
    remove_column :games, :starts_at
  end
end
