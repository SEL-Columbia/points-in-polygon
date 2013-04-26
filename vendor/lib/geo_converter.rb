module GeoConverter

  def self.topojson_to_geojson_file(upload)
    geojson_dir = Rails.root.join("tmp/topojson_to_geojson/#{SecureRandom.hex(15)}")
    FileUtils.mkdir_p(geojson_dir)
    system %{geojson -o #{geojson_dir} #{upload.tempfile.path}}
    # FileUtils.rm_rf geojson_dir
    geojson_dir
  end

  def to_topojson
    unless @topojson
      if File.exists? topojson_file_save_path
        @topojson = File.read(topojson_file_save_path)
      end
    end
    @topojson
  end

  def save_topojson_file
    if @topojson_file && File.exist?(@topojson_file)
      FileUtils.mv(@topojson_file, topojson_file_save_path)
    end
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

end
