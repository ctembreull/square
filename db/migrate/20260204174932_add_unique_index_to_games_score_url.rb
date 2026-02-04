class AddUniqueIndexToGamesScoreUrl < ActiveRecord::Migration[8.1]
  def change
    add_index :games, :score_url, unique: true
  end
end
