class AddRuntimeStyleToStyles < ActiveRecord::Migration[8.1]
  def change
    add_column :styles, :runtime_style, :boolean, default: false, null: false
  end
end
