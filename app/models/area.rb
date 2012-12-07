class Area < ActiveRecord::Base
  attr_accessible :polygon

  belongs_to :layer

  RGEO_FACTORY = RGeo::Geographic.simple_mercator_factory
  set_rgeo_factory_for_column :polygon, RGEO_FACTORY.projection_factory

  EWKB = RGeo::WKRep::WKBGenerator.new(:type_format => :ewkb, :emit_ewkb_srid => true, :hex_format => true)

  # polygon_contains_point([-74.006605, 40.714623])
  scope :polygon_contains_point, lambda { |lon_lat|
    lon, lat = lon_lat
    ewkb = EWKB.generate(RGEO_FACTORY.point(lon, lat).projection)
    where("ST_Intersects(polygon, ST_GeomFromEWKB(E'\\\\x#{ewkb}'))")
  }

  # polygon_contains_points([[-74.006605, 40.714623], ...])
  scope :polygon_contains_points, lambda { |lon_lats|
    conditions = []
    lon_lats.each do |lon_lat|
      lon, lat = lon_lat
      ewkb = EWKB.generate(RGEO_FACTORY.point(lon, lat).projection)
      conditions << "ST_Intersects(polygon, ST_GeomFromEWKB(E'\\\\x#{ewkb}'))"
    end
    conditions = conditions.join(" or ")
    where(conditions)
  }

  # polygon_contains_points([[-74.006605, 40.714623], ...])
  scope :contains_points_in_layer, lambda { |layer_id, points|
    lon_lats = points.map{|point| [point[:lon], point[:lat]] }

    conditions = []
    lon_lats.each do |lon_lat|
      lon, lat = lon_lat
      ewkb = EWKB.generate(RGEO_FACTORY.point(lon, lat).projection)
      conditions << "ST_Intersects(polygon, ST_GeomFromEWKB(E'\\\\x#{ewkb}'))"
    end
    conditions = conditions.join(" or ")
    where(conditions).joins(:layer).where("layers.id = ?", layer_id)
  }

  def self.contains_points_in_layer_json(layer_id, query_points)
    areas = contains_points_in_layer(layer_id, query_points)

    points_in_area = []
    areas.each do |area|
      points = area.filter_including_points(query_points)
      area_as_json = {
        :layer_id => area.layer_id,
        :area_id  => area.id,
        :points   => points,
        :pointsWithinCount    => points.count
      }
      points_in_area << area_as_json
    end

    points_in_area
  end


  def filter_including_points(filter_points)
    filter_points.find_all do |point|
      lon_lat = RGEO_FACTORY.point(point[:lon], point[:lat]).projection
      lon_lat.within?(polygon)
      # polygon.intersects?(lon_lat)
    end
  end

  # result is like below
  # {:points_in_area=>
  # [{:layer_id=>18,
  #   :area_id=>367,
  #   :points=>[{:id=>"456", :lon=>"8.568907", :lat=>"47.373419"}],
  #   :pointsWithinCount=>1},
  #  {:layer_id=>18, :area_id=>568, :points=>[], :pointsWithinCount=>0}]}
  def get_points_count(result)
    # debugger
    area_in_result = result[:points_in_area].find{ |a| a[:area_id] == self.id }
    area_in_result ? area_in_result[:pointsWithinCount] : 0
  end

end
