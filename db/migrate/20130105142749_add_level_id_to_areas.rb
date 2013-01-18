class AddLevelIdToAreas < ActiveRecord::Migration
  def change
    add_column :areas, :level_id, :integer
    add_column :areas, :parent_id, :integer
  end
end
