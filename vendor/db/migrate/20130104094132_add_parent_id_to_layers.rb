class AddParentIdToLayers < ActiveRecord::Migration
  def change
    add_column :layers, :parent_id, :integer
  end
end
