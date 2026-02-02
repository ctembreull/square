class RemoveActiveFromEvents < ActiveRecord::Migration[8.1]
  def change
    remove_column :events, :active, :boolean
  end
end
