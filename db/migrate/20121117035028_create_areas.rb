class CreateAreas < ActiveRecord::Migration
  def change
    create_table :areas do |t|
      t.integer :layer_id
      t.polygon :polygon, :geometry => true, :srid => 3785

      t.timestamps
    end

    add_index(:areas, :polygon, :spatial => true)  # spatial index
  end
end
