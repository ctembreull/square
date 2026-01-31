class AddEspnApiUrlToGames < ActiveRecord::Migration[8.1]
  def change
    add_column :games, :espn_api_url, :string
  end
end
