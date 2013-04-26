class AddUnprojectExteriorRingToAreas < ActiveRecord::Migration
  def change
    add_column :areas, :unproject_exterior_ring, :text
  end
end
