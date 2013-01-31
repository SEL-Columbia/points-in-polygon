require 'zip/zipfilesystem'
require 'csv'

class Layer < ActiveRecord::Base
  attr_accessor :geo_file
  attr_accessible :name, :geo_file, :parent_id
  validates :geo_file, :presence => true, :on => :create

  has_many :areas, :dependent => :destroy
  belongs_to :parent, :class_name => 'Layer', :foreign_key => 'parent_id'
  has_one :child, :class_name => 'Layer', :foreign_key => 'parent_id'

  before_create :set_name_from_upload_file
  after_create :save_topojson_file

  class << self
    def create_from_topojson(upload)
      created = []
      # convert topojson file to geojson data
      geojson_dir = topojson_file_to_geojson(upload)

      # create layers with geojson data
      Dir[File.join(geojson_dir, "*")].each do |geojson_file_path|
        geojson_file = File.open(geojson_file_path)
        # acts as a uploaded file
        geojson_file.define_singleton_method(:original_filename) { File.basename(geojson_file.path) }
        geojson_file.define_singleton_method(:tempfile) { geojson_file }
        # create layer
        layer = Layer.new(:geo_file => geojson_file)
        layer.save if layer.areas.size > 0
        created << layer unless layer.new_record?
      end

      # clear tmp files
      FileUtils.rm_rf geojson_dir

      created
    end

    def topojson_file_to_geojson(upload)
      geojson_dir = Rails.root.join("tmp/topojson_to_geojson/#{SecureRandom.hex(15)}")
      FileUtils.mkdir_p(geojson_dir)
      system %{geojson -o #{geojson_dir} #{upload.tempfile.path}}
      # FileUtils.rm_rf geojson_dir
      geojson_dir
    end
  end

  def geo_file=(upload_file)
    # The comparing method should be improved
    if upload_file.class == ActionDispatch::Http::UploadedFile || upload_file.class == File
      @geo_file = upload_file
    elsif upload_file[:tempfile].class == ActionDispatch::Http::UploadedFile
      @geo_file = upload_file[:tempfile]
    else
      return true
    end
    # convert geojson file to polygons data
    geojson_file_to_areas(@geo_file.read)
    # convert geojson file to topojson file
    geojson_file_to_topojson_file(@geo_file)
  end

  def self.upload_shapefile(params)
    random_dir = SecureRandom.hex(15)
    base_path = "tmp/shapefiles/#{random_dir}"
    layers = []

    if params[:geo_file].class == ActionDispatch::Http::UploadedFile
      @shapefile = params[:geo_file]
    elsif params[:geo_file][:tempfile].class == ActionDispatch::Http::UploadedFile
      @shapefile = params[:geo_file][:tempfile]
    else
      return true
    end

    Zip::ZipFile.open(@shapefile.path) do |zipfile|
      # Extract all the file to tmp/shapefiles
      zipfile.each do |entry|
        file_path = File.join(base_path, entry.name)
        FileUtils.mkdir_p(File.dirname(file_path))
        zipfile.extract(entry, file_path) unless File.exist?(file_path)
      end

      has_csv = false;
      level = 0
      id_tree = {}

      # Handle the shapefiles
      zipfile.each do |entry|
        file_path = File.join(base_path, entry.name)
        if entry.name.match(/.*\.shp$/)
          params.delete(:geo_file)
          layers.push Layer.new(params.merge({:name => params[:name] + "_#{entry.name[0..-5]}"})).ziped_shapefile_to_areas(file_path)
        elsif entry.name.match(/.*\.csv$/)
          csv_data = CSV.read file_path
          header = csv_data.shift.map { |i| i.to_s }
          data = csv_data.map {|row| row.map {|cell| cell.to_s } }
          array_of_hashes = data.map {|row| Hash[*header.zip(row).flatten] }
          id_tree[level] = array_of_hashes.map {|i| { :level_id => i["ID_#{level}"].to_i, :parent_id => i["ID_#{level-1}"].to_i}}
          level += 1
          has_csv = true;
        end
      end
      if has_csv
        id_tree.each_pair do |k, v|
          layers[k].areas.each_with_index do |a, i|
            a.update_attributes({:parent_id => v[i][:parent_id], :level_id => v[i][:level_id]})
          end
        end
      end
    end
    # Delete all the files after handling
    FileUtils.rm_rf Dir.glob(base_path)
    layers
  end

  def ziped_shapefile_to_areas(file_path)
    @geo_file = file_path
    geo_factory = RGeo::Geographic.simple_mercator_factory
    RGeo::Shapefile::Reader.open(@geo_file, :factory => geo_factory, :srid => 3785) do |file|
      file.each do |record|
        build_areas record.geometry
      end
      file.rewind
      record = file.next
    end
    self
  end

  def geojson_file_to_areas(json_str)
    geo_factory = RGeo::Geographic.simple_mercator_factory
    geo_json = RGeo::GeoJSON.decode(json_str, :json_parser => :json, :geo_factory => geo_factory)
    # TODO: checout why geo_json is nil if geojson_file.original_filename == "land.json" (upload public/topojson_sample/us.json)
    build_areas geo_json
  end

  def geojson_file_to_topojson_file(geo_file)
    topojosn_file_path = Rails.root.join("tmp", "#{SecureRandom.hex(15)}.topojson")
    # use `topojson` command to convert geojson to topojson
    system %{topojson -p true -o #{topojosn_file_path} #{geo_file.tempfile.path}}
    @topojson_file = topojosn_file_path if File.exist?(topojosn_file_path)
  end

  def build_areas(geo_entry)
    areas.delete_all
    case geo_entry
    when RGeo::Geographic::ProjectedMultiPolygonImpl
      areas.build :multipolygon => geo_entry.projection
      #geo_entry.entries.each do |polygon|
      #  areas.build :polygon => polygon.projection
      #end
    when RGeo::Geographic::ProjectedPolygonImpl
      areas.build :polygon => geo_entry.projection
    when RGeo::GeoJSON::FeatureCollection
      geo_entry.each do |feature|
        geometry = feature.geometry
        case geometry
        when RGeo::Geographic::ProjectedMultiPolygonImpl
          areas.build :multipolygon => geometry.projection
          #geometry.entries.each do |polygon|
          #  areas.build :polygon => polygon.projection
          #end
        when RGeo::Geographic::ProjectedPolygonImpl
          areas.build :polygon => geometry.projection
        end
      end
    when RGeo::Geographic::ProjectedGeometryCollectionImpl # from a geojson converted from topojson
      geo_entry.each do |geometry|
        case geometry
        when RGeo::Geographic::ProjectedMultiPolygonImpl
          areas.build :multipolygon => geometry.projection
          #geometry.entries.each do |polygon|
          #  areas.build :polygon => polygon.projection
          #end
        when RGeo::Geographic::ProjectedPolygonImpl
          areas.build :polygon => geometry.projection
        end
      end
    end
  end

  def set_name_from_upload_file
    self.name = geo_file.original_filename if geo_file && name.blank?
  end

  def topojson_file_save_path
    unless @topojson_file_save_path
      base_path = Rails.root.join("public", "system", "topojson")
      FileUtils.mkdir_p(base_path)
      @topojson_file_save_path = File.join(base_path, "#{id}.topojson")
    end
    @topojson_file_save_path
  end

  def to_topojson
    unless @topojson
      if File.exists? topojson_file_save_path
        @topojson = File.read(topojson_file_save_path)
      end
    end
    @topojson
  end

  private

    def save_topojson_file
      if @topojson_file && File.exist?(@topojson_file)
        FileUtils.mv(@topojson_file, topojson_file_save_path)
      end
    end
end
