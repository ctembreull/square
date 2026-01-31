class ChangeEspnIdIndexToNonUnique < ActiveRecord::Migration[8.1]
  def change
    # ESPN IDs are only unique within a sport, not globally
    # (e.g., NFL team ID 9 is Cardinals, MBB team ID 9 is Arizona State)
    remove_index :teams, :espn_id
    add_index :teams, :espn_id
  end
end
