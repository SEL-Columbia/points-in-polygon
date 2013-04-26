class CreatePoints < ActiveRecord::Migration
  def change
    create_table :points do |t|
      t.string :name
      t.decimal :lat
      t.decimal :lon
      t.point :lat_lon, :geometry => true, :srid => 3785
    end

    add_index(:points, :lat_lon, :spatial => true)
  end
end
