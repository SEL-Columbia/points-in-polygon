class AddMultipolygonToAreas < ActiveRecord::Migration
  def change
    add_column :areas, :multipolygon, :geometry, :srid => 3785

    add_index :areas, :multipolygon, :spatial => true
  end
end
