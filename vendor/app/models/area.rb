require 'json'
class Area < ActiveRecord::Base
  attr_accessible :polygon, :multipolygon, :unproject_exterior_ring, :level_id, :parent_id
  #serialize :unproject_exterior_ring, Array

  belongs_to :layer

  RGEO_FACTORY = RGeo::Geographic.simple_mercator_factory
  set_rgeo_factory_for_column :polygon, RGEO_FACTORY.projection_factory
  set_rgeo_factory_for_column :multipolygon, RGEO_FACTORY.projection_factory

  EWKB = RGeo::WKRep::WKBGenerator.new(:type_format => :ewkb, :emit_ewkb_srid => true, :hex_format => true)

  # polygon_contains_points([[-74.006605, 40.714623], ...])
  scope :polygon_contains_points, lambda { |lon_lats, tolerance = nil|
    conditions = []
    polygon_sql = tolerance ? "ST_simplify(polygon, #{tolerance})" : "polygon"
    multipolygon_sql = tolerance ? "ST_simplify(polygon, #{tolerance})" : "multipolygon"

    lon_lats.each do |lon_lat|
      lon, lat = lon_lat[:lon], lon_lat[:lat]
      ewkb = EWKB.generate(RGEO_FACTORY.point(lon, lat).projection)
      conditions << "ST_Intersects(#{polygon_sql}, ST_GeomFromEWKB(E'\\\\x#{ewkb}')) or ST_Intersects(#{multipolygon_sql}, ST_GeomFromEWKB(E'\\\\x#{ewkb}'))"
    end

    conditions = conditions.join(" or ")
    where(conditions)
  }

  # polygon_contains_points([[-74.006605, 40.714623], ...])
  scope :contains_points_in_layer, lambda { |layer_id, points, tolerance|
    lon_lats = points.map{|point| [point[:lon], point[:lat]] }

    conditions = []
    polygon_sql = tolerance ? "ST_simplify(polygon, #{tolerance})" : "polygon"
    multipolygon_sql = tolerance ? "ST_simplify(polygon, #{tolerance})" : "multipolygon"

    lon_lats.each do |lon_lat|
      lon, lat = lon_lat
      ewkb = EWKB.generate(RGEO_FACTORY.point(lon, lat).projection)
      conditions << "ST_Intersects(#{polygon_sql}, ST_GeomFromEWKB(E'\\\\x#{ewkb}')) or ST_Intersects(#{multipolygon_sql}, ST_GeomFromEWKB(E'\\\\x#{ewkb}'))"
    end
    conditions = conditions.join(" or ")
    where(conditions).joins(:layer).where("layers.id = ?", layer_id)
  }

  def self.points_count_in_layer(layer_id, points, tolerance)
    layer = Layer.find(layer_id)

    points_count = []
    layer.areas.each do |area|
      queried_points = area.filter_including_points(points)
      points_count << {:area_id => area.id, :count => queried_points.count}
    end
    points_count
  end

  # deprecated
  def self.contains_points_in_layer_json(layer_id, query_points, tolerance)
    areas = contains_points_in_layer(layer_id, query_points, tolerance)

    points_in_area = []
    areas.each do |area|
      points = area.filter_including_points(query_points)
      area_as_json = {
        :layer_id => area.layer_id,
        :area_id  => area.id,
        :points   => points,
        :pointsWithinCount => points.count
      }
      points_in_area << area_as_json
    end

    points_in_area
  end


  def filter_including_points(filter_points)
    filter_points.find_all do |point|
      lon_lat = RGEO_FACTORY.point(point[:lon], point[:lat]).projection
      lon_lat.within?(polygon || multipolygon)
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
    area_in_result = result[:points_in_area].find{ |a| a[:area_id] == self.id }
    area_in_result ? area_in_result[:pointsWithinCount] : 0
  end

  def get_row_indexes(result)
    area_in_result = result[:points_in_area].find { |a| a[:area_id] == self.id }
    area_in_result ? area_in_result[:row_indexes] : [-1]
  end

  # Return simplified polygon
  def simplified_polygon(tolerance)
    if tolerance
      geos_poly = polygon ? polygon.fg_geom : multipolygon.fg_geom
      simplified_geos_poly = geos_poly.simplify(tolerance)
      Area::RGEO_FACTORY.projection_factory.wrap_fg_geom(simplified_geos_poly)
    else
      polygon ? polygon.fg_geom : multipolygon.fg_geom
    end
  end

  after_create :save_unproject_exterior_ring
  def save_unproject_exterior_ring
    if self.polygon
      self.update_attributes(:unproject_exterior_ring => JSON.generate((Area::RGEO_FACTORY.unproject self.polygon.exterior_ring).points.map{|point| [point.y, point.x]}))
    elsif self.multipolygon
      u_e_r = []
      self.multipolygon.each do |p|
        u_e_r << (Area::RGEO_FACTORY.unproject p.exterior_ring).points.map{|point| [point.y, point.x]}
      end
      self.update_attributes(:unproject_exterior_ring => JSON.generate(u_e_r))
    else
      return true
    end
    self.save
  end

end
