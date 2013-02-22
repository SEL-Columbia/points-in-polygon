collection @layers => :layers
attributes :id, :name
node(:number_of_polygons) { |layer| layer.areas.count }

# example on top is equal to the code below
# render json: {layers: @layers.map {|layer| {id: layer.id, name:layer.name, number_of_polygons: layer.areas.count}}}
