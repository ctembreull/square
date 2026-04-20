class AddEmailSignatureToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_signature, :text
  end
end
