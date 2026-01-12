class RemoveDivisionsFromApp < ActiveRecord::Migration[8.1]
  def change
    # Remove division_id from affiliations
    remove_reference :affiliations, :division, foreign_key: true

    # Drop the divisions table
    drop_table :divisions do |t|
      t.string :abbr, null: false
      t.bigint :conference_id, null: false
      t.string :display_name, null: false
      t.string :name, null: false
      t.integer :order, default: 0, null: false
      t.timestamps
      t.index [:conference_id, :name], unique: true
      t.index [:conference_id]
    end
  end
end
