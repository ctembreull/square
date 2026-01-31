class AddEspnFieldsToTeamsAndLeagues < ActiveRecord::Migration[8.1]
  def change
    # Teams: ESPN team ID and sport-specific slugs
    add_column :teams, :espn_id, :integer
    add_column :teams, :espn_mens_slug, :string
    add_column :teams, :espn_womens_slug, :string
    add_index :teams, :espn_id, unique: true
    add_index :teams, :espn_mens_slug
    add_index :teams, :espn_womens_slug

    # Leagues: ESPN API path segment (e.g., "mens-college-basketball")
    add_column :leagues, :espn_slug, :string
    add_index :leagues, :espn_slug, unique: true
  end
end
