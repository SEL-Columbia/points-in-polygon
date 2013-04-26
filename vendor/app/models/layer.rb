require 'fileutils'
require 'zip/zipfilesystem'
require 'csv'

class Layer < ActiveRecord::Base
  attr_accessor :file
  attr_accessible :name, :file, :parent_id
  validates :file, :presence => true, :on => :create

  has_many :areas, :dependent => :destroy
  belongs_to :parent, :class_name => 'Layer', :foreign_key => 'parent_id'
  has_one :child, :class_name => 'Layer', :foreign_key => 'parent_id'

  before_create :set_name_from_upload_file
  after_create :save_topojson_file

  class << self
    def create_from_topojson(layer)
      upload = layer[:file]
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
        layer = Layer.new(:file => geojson_file, :name => layer[:name])
        layer.save if layer.areas.size > 0
        created << layer unless layer.new_record?
        layer
      end

      # clear tmp files
      FileUtils.rm_rf geojson_dir

      created
    end

    def topojson_file_to_geojson(upload)
      geojson_dir = Rails.root.join("tmp/topojson_to_geojson/#{SecureRandom.hex(15)}")
      geojson_file = File.join(geojson_dir, upload.original_filename)
      FileUtils.mkdir_p(geojson_dir)
      system %{geojson -o #{geojson_dir} #{upload.tempfile.path}}
      geojson_dir
    end

  end

  # Filter the valid file before update_attributes
  def update_with_valid_file(params)
    file = params[:file]
    return false if file.blank? || !file.respond_to?(:original_filename)
    format = File.extname(file.original_filename)

    case format
    when '.geojson' then update_attributes(params)
    when '.geo.json' then update_attributes(params)
    # Topojson
    when '.json'
      valid_topojson(file, params)
    # shapefile
    when '.zip'
      valid_shapefile(file, params)
    else false
    end
  end

  def valid_topojson(file, params)
    result = false
    geojson_dir = Layer.topojson_file_to_geojson(file)
    paths = Dir[File.join(geojson_dir, "*")]
    if paths.count == 1
      geojson_file = File.open(paths[0])
      # acts as a uploaded file
      geojson_file.define_singleton_method(:original_filename) { File.basename(geojson_file.path) }
      geojson_file.define_singleton_method(:tempfile) { geojson_file }
      areas.destroy_all if areas.length > 0
      params[:file] = geojson_file
      result = update_attributes(params)
    end
    # clear tmp files
    FileUtils.rm_rf geojson_dir
    result
  end

  def valid_shapefile(file, params)
    result = false
    shapefile, base_path = Layer.extract_zipped_shapefile(params)
    Zip::ZipFile.open(shapefile.path) do |zipfile|
      shapes = zipfile.select { |e| e.name =~ /^\w*\.shp$/ }
      params.delete(:file)
      if shapes.count == 1
        areas.destroy_all if areas.length > 0
        file_path = File.join(base_path, shapes.first.name)
        result = ziped_shapefile_to_areas(file_path).update_attributes(params)
      end
    end
    # Delete all the files after handling
    FileUtils.rm_rf Dir.glob(base_path)
    result
  end

  # The file uploaded, which will be used to create the geo data
  # Only create one layer one time
  def file=(upload_file)
    # The comparing method should be improved
    if upload_file.class == ActionDispatch::Http::UploadedFile || upload_file.class == File
      @file = upload_file
    # For the sinatra demo end
    # TODO: refactor this
    elsif upload_file.respond_to?(:tempfile) and upload_file.tempfile.class == ActionDispatch::Http::UploadedFile
      @file = upload_file[:tempfile]
    end

    # When update the layer, destroy all the areas first
    if areas.length > 0
      areas.destroy_all
    end

    # convert geojson file to polygons data
    geojson_file_to_areas(@file.read)
    # convert geojson file to topojson file, then the topojson data can be get from the layer
    geojson_file_to_topojson_file(@file)
  end

  def self.extract_zipped_shapefile(params)
    random_dir = SecureRandom.hex(15)
    base_path = "tmp/shapefiles/#{random_dir}"
    result = false

    if params[:file].class == ActionDispatch::Http::UploadedFile
      result = [params[:file], base_path]
    elsif params[:file][:tempfile].class == ActionDispatch::Http::UploadedFile
      result = [params[:file][:tempfile], base_url]
    end

    return false unless result

    Zip::ZipFile.open(result[0].path) do |zipfile|
      # Extract all the file to tmp/shapefiles
      zipfile.each do |entry|
        file_path = File.join(base_path, entry.name)
        FileUtils.mkdir_p(File.dirname(file_path))
        zipfile.extract(entry, file_path) unless File.exist?(file_path)
      end
    end
    result
  end

  def self.upload_shapefile(params)
    layers = []
    @shapefile, base_path = extract_zipped_shapefile(params)
    unless @shapefile
      return false
    end
    Zip::ZipFile.open(@shapefile.path) do |zipfile|

      has_csv = false;
      level = 0
      id_tree = {}

      # Handle the shapefiles
      zipfile.each do |entry|
        file_path = File.join(base_path, entry.name)
        if entry.name.match(/^\w*\.shp$/)
          params.delete(:file)
          layers.push Layer.new(params.merge({:name => params[:name] + "_#{entry.name[0..-5]}"})).ziped_shapefile_to_areas(file_path)
          write_geojson_file(file_path, layers.last)
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

  def self.write_geojson_file(file_path, layer)
    # this will not work with multiple files. i need handle this better
    file_name = SecureRandom.hex(8) + '.geojson'
    tmp_dir = Rails.root.join("tmp", SecureRandom.hex(15))
    geojson_file_path = File.join(tmp_dir, file_name)
    FileUtils.mkdir_p(tmp_dir)
    system %(ogr2ogr -f "GeoJSON" #{geojson_file_path} #{Rails.root.join(file_path)} )
    geojson_file = File.open(geojson_file_path)
    layer.geojson_file_to_topojson_file(geojson_file)
  end

  def ziped_shapefile_to_areas(file_path)
    @file = file_path

    geo_factory = RGeo::Geographic.simple_mercator_factory
    RGeo::Shapefile::Reader.open(@file, :factory => geo_factory, :srid => 3785) do |file|
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
    # Get the geometry from the geojson
    geom = RGeo::GeoJSON.decode(json_str, :json_parser => :json, :geo_factory => geo_factory)

    # If the file is topojson, geom is nil
    if !geom
      return true
    end
    build_areas geom
  end

  def geojson_file_to_topojson_file(file)
    if file.class == ActionDispatch::Http::UploadedFile || file.class == File
      file = file
    elsif file.tempfile.class == ActionDispatch::Http::UploadedFile || file.tempfile.class == File
      file = file.tempfile
    end
    topojson_file_path = Rails.root.join("tmp", "#{SecureRandom.hex(15)}.topojson")
    # use `topojson` command to convert geojson to topojson
    system %{topojson -p true -o #{topojson_file_path} #{file.path}}
    @topojson_file = topojson_file_path if File.exist?(topojson_file_path)
  end

  def build_areas(geo_entry)
    case geo_entry
    when RGeo::Geographic::ProjectedMultiPolygonImpl
      areas.build :multipolygon => geo_entry.projection
    when RGeo::Geographic::ProjectedPolygonImpl
      areas.build :polygon => geo_entry.projection
    when RGeo::GeoJSON::FeatureCollection
      geo_entry.each do |feature|
        geometry = feature.geometry
        case geometry
        when RGeo::Geographic::ProjectedMultiPolygonImpl
          areas.build :multipolygon => geometry.projection
        when RGeo::Geographic::ProjectedPolygonImpl
          areas.build :polygon => geometry.projection
        end
      end
    when RGeo::Geographic::ProjectedGeometryCollectionImpl # from a geojson converted from topojson
      geo_entry.each do |geometry|
        case geometry
        when RGeo::Geographic::ProjectedMultiPolygonImpl
          areas.build :multipolygon => geometry.projection
        when RGeo::Geographic::ProjectedPolygonImpl
          areas.build :polygon => geometry.projection
        end
      end
    end
  end

  def set_name_from_upload_file
    self.name = file.original_filename if file && name.blank?
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
