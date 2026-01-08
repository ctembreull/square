class AddDisplayNameToConferences < ActiveRecord::Migration[8.1]
  def up
    add_column :conferences, :display_name, :string

    Conference.where(display_name: nil).update_all(display_name: " ")

    change_column :conferences, :display_name, :string, null: false
  end

  def down
    remove_column :conferences, :display_name
  end
end
