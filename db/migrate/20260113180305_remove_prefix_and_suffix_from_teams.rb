class RemovePrefixAndSuffixFromTeams < ActiveRecord::Migration[8.1]
  def change
    remove_column :teams, :prefix, :string
    remove_column :teams, :suffix, :string
  end
end
