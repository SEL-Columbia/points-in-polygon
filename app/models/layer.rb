class Layer < ActiveRecord::Base
  attr_accessor :geojson_file
  attr_accessible :name, :geojson_file
  validates :geojson_file, :presence => true, :on => :create

  has_many :areas

  before_create :set_name_from_upload_file

  def geojson_file=(upload_file)
    @geojson_file = upload_file
    # convert geojson file to polygons data
    geojosn_file_to_areas(@geojson_file.read)
  end

  def geojosn_file_to_areas(json_str)
    geo_factory = RGeo::Geographic.simple_mercator_factory
    geo_json = RGeo::GeoJSON.decode(json_str, :json_parser => :json, :geo_factory => geo_factory)

    case geo_json
    when RGeo::Geographic::ProjectedMultiPolygonImpl
      geo_json.entries.each do |polygon|
        areas.build :polygon => polygon.projection
      end
    when RGeo::Geographic::ProjectedPolygonImpl
      areas.build :polygon => geo_json.projection
    when RGeo::GeoJSON::FeatureCollection
      # debugger
      geo_json.each do |feature|
        # debugger
        geometry = feature.geometry
        case geometry
        when RGeo::Geographic::ProjectedMultiPolygonImpl
          geometry.entries.each do |polygon|
            areas.build :polygon => polygon.projection
          end
        when RGeo::Geographic::ProjectedPolygonImpl
          areas.build :polygon => geometry.projection
        end
      end
    end
  end

  def set_name_from_upload_file
    self.name = geojson_file.original_filename if geojson_file && name.blank?
  end
end
