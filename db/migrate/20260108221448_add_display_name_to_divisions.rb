class AddDisplayNameToDivisions < ActiveRecord::Migration[8.1]
  def up
    add_column :divisions, :display_name, :string

    Division.where(display_name: nil).update_all(display_name: " ")

    change_column :divisions, :display_name, :string, null: false
  end

  def down
    remove_column :divisions, :display_name
  end

end
