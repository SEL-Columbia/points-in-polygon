object @layer
attributes :id, :name
node(:number_of_polygons) { |l| l.areas.count }
