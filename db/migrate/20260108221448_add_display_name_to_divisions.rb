class AddDisplayNameToDivisions < ActiveRecord::Migration[8.1]
  def up
    add_column :divisions, :display_name, :string

    execute "UPDATE divisions SET display_name = ' ' WHERE display_name IS NULL"

    change_column :divisions, :display_name, :string, null: false
  end

  def down
    remove_column :divisions, :display_name
  end

end
