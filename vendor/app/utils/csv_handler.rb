class CsvHandler
  attr_reader :points_with_index, :filters, :header
  def initialize(path)
    csv_data = CSV.read(path)

    @header = csv_data[0]
    @body = csv_data[1..-1].map do |row|
      Hash[@header.zip(row)]
    end
  end

  def get_xy_str(params_lon, params_lat)
    lat = @header.select{|h| h and h.match 'lat'}
    lon = @header.select{|h| h and h.match 'lon'}
    lat = [params_lat] unless params_lat.blank?
    lon = [params_lon] unless params_lon.blank?
    @lat_str, @lon_str = lat[0], lon[0]
    return lat, lon
  end

  def find_filters
    unique = Hash.new { |h, k| h[k] = {} }
    @header.each do |col|
      unique[col] = Hash.new(0)
      @body.each { |item| unique[col][item[col]] += 1 }
    end
    @filters = @header.select{ |col| unique[col].length < Math.sqrt(@body.length) }
  end

  def csv_to_db
    new_csv = "lat,lon,row_index,attrs_json\r\n"
    @points_with_index = []
    @body.each_with_index do |row, index|
      lat, lon = row.fetch(@lat_str), row.fetch(@lon_str)
      attrs_json = JSON.generate(row)
      if lat.match(/\d+.\d*/) and lon.match(/\d+.\d*/)
        # TODO need a better way to handle the separation
        new_csv << "#{lat},#{lon},#{index},#{attrs_json.gsub(',', ';;;!!!').gsub('\r\n', '').gsub('\n', '')}\r\n"
        @points_with_index << {:lat => lat, :lon => lon, :index => index}
      end
    end
    rand_name = SecureRandom.hex(18)
    file_path = Rails.root.join('tmp/csv', rand_name + '.csv')
    FileUtils.mkdir_p(File.dirname(file_path))
    File.open(file_path, 'w') { |f| f.write(new_csv) }

    # create a temp table
    table_name = "points#{SecureRandom.hex(10)}"
    create_sql = "CREATE TABLE #{table_name}(lat float, lon float, row_index integer, attrs_json text)"
    ActiveRecord::Base.connection.execute(create_sql)

    # copy the data in the csv file to the temp table
    import_sql = "COPY #{table_name}(lat, lon, row_index, attrs_json) FROM '#{file_path}' DELIMITERS ',' CSV HEADER QUOTE '\"' ESCAPE E'\\\\\'"
    ActiveRecord::Base.connection.execute(import_sql)

    # delete the csv file
    FileUtils.rm file_path
    table_name
  end
end
