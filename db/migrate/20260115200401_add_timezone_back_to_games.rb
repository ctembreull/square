class AddTimezoneBackToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :timezone, :string, default: "America/New_York"
  end
end
