class RemoveBodyFromPosts < ActiveRecord::Migration[8.1]
  def change
    remove_column :posts, :body, :text
  end
end
