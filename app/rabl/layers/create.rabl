collection @layers => :layers
attributes :id, :name
node(:number_of_polygons) { |layer| layer.areas.count }
