module FactoryGirlHelpers
  def self.upload_geojson_file(location = nil)
    location = (location) ? location : 'manhattan_geojson.geojson'
    upload_file('geojson', 'geojson', location)
  end
  def self.upload_topojson_file(location = nil)
    location = (location) ? location : 'manhattan_topojson.json'
    upload_file('topojson', 'json', location)
  end
  def self.upload_shapefile(location = nil)
    location = (location) ? location : 'manhattan_shapefile.zip'
    upload_file('shapefile', 'zip', location)
  end

  private
  def self.upload_file(folder, extension,  location = nil)
    file = File.new(Rails.root + "spec/fixtures/#{folder}/#{location}")
    file.rewind
    ActionDispatch::Http::UploadedFile.new(:tempfile => file, :filename => File.basename(file))
  end
end
