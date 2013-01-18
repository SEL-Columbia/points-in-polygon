class Point < ActiveRecord::Base
  attr_accessible :name, :lat, :lon, :lat_lon

  def self.csv_to_temp_points(csv_body, lat, lon, layer_id)
    # generate a new csv file
    new_csv = "#{lat},#{lon},row_index\n"
    csv_body.each_with_index { |row, index|
      new_csv << "#{row[lat]},#{row[lon]},#{index}\n" if row[lat].match(/\d+.\d*/) and row[lon].match(/\d+.\d*/)
    }
    rand_name = SecureRandom.hex(18)
    file_path = Rails.root.join('tmp/csv', rand_name + '.csv')
    FileUtils.mkdir_p(File.dirname(file_path))
    File.open(file_path, 'w') { |f| f.write(new_csv) }

    # create a temp table
    table_name = "points#{SecureRandom.hex(10)}"
    create_sql = "CREATE TABLE #{table_name}(lat float, lon float, row_index integer)"
    ActiveRecord::Base.connection.execute(create_sql)

    # copy the data in the csv file to the temp table
    import_sql = "COPY #{table_name}(lat, lon, row_index) FROM '#{file_path}' DELIMITERS ',' CSV HEADER"
    ActiveRecord::Base.connection.execute(import_sql)

    # delete the csv file
    FileUtils.rm file_path

    # add a geometry column to the temp table
    add_geometry_sql = "SELECT AddGeometryColumn('public', '#{table_name}', 'lon_lat', 3785, 'POINT', 2)"
    ActiveRecord::Base.connection.execute(add_geometry_sql)

    # update the geometry column in the table
    trans_sql = "UPDATE #{table_name} SET lon_lat = ST_SetSRID(ST_Transform(ST_SetSRID(ST_MakePoint(lon, lat), 4326), 900913), 3785)"
    ActiveRecord::Base.connection.execute(trans_sql)

    # create indexes to the geometry column
    index_sql = "CREATE INDEX #{table_name}_lon_lat ON #{table_name} USING GIST ( lon_lat )"
    ActiveRecord::Base.connection.execute(index_sql)

    begin
      # temp table for the dumped areas
      #area_table_name = "area#{SecureRandom.hex(10)}"
      #ActiveRecord::Base.connection.execute("CREATE TABLE #{area_table_name} AS SELECT areas.id as area_id, (ST_Dump(areas.multipolygon)).geom as multi_geom, areas.polygon as poly_geom FROM areas WHERE (areas.layer_id = #{layer_id})")

      # create index for the areas table
      #ActiveRecord::Base.connection.execute("CREATE INDEX #{area_table_name}_multi_geom on #{area_table_name} USING GIST (multi_geom)")
      #ActiveRecord::Base.connection.execute("CREATE INDEX #{area_table_name}_poly_geom on #{area_table_name} USING GIST (poly_geom)")

      #begin
      # get the intersect result by executing the sql
      intersect_sql = "SELECT dumped_areas.area_id, points.lon, points.lat, points.row_index FROM (SELECT areas.id as area_id, (ST_Dump(areas.multipolygon)).geom as multi_geom, areas.polygon as poly_geom FROM areas WHERE (areas.layer_id = #{layer_id})) as dumped_areas, #{table_name} as points WHERE (dumped_areas.poly_geom is not NULL and ST_Intersects(dumped_areas.poly_geom, points.lon_lat)) or (dumped_areas.multi_geom is not NULL and ST_Intersects(dumped_areas.multi_geom, points.lon_lat))"
      intersect_result = ActiveRecord::Base.connection.execute(intersect_sql)
      query_result = intersect_result.values
      #ensure
      #  ActiveRecord::Base.connection.execute("DROP TABLE #{area_table_name}")
      #end

    ensure
      # drop the temp table
      # FOR demo
      #drop_sql = "DROP TABLE #{table_name}"
      #ActiveRecord::Base.connection.execute(drop_sql)
    end

    # make a hash {"AREA_ID" => [entry1, entry2]}
    area_entries = {}
    query_result.each do |entry|
      area_entries[entry[0]] = [] if !area_entries.has_key? entry[0]
      area_entries[entry[0]] << entry
    end

    # put the data to the points_in_area and return it
    all_areas = {}
    Area.where(:id => query_result.map{|r| r[0]}.uniq).each {|a| all_areas[a.id] = a}
    points_in_area = []
    all_areas.each_pair do |aid, area|
      entries = area_entries[aid.to_s]
      points = entries.map { |e| [e[1], e[2]] }
      row_indexes = entries.map { |e| e[3] }
      points_in_area << {
        :layer_id => area.layer_id,
        :area_id => area.id,
        :points => points,
        :pointsWithinCount => entries.length,
        :row_indexes => row_indexes
      }
    end
    {:points_in_area => points_in_area, :table_name => table_name}
  end

  # origin method, slower
  #def self.csv_to_points(csv_body, lat, lon, layer_id)
  #  new_csv = "#{lat},#{lon},name,row_index\n"
  #  rand_name = SecureRandom.hex(18)
  #  csv_body.each_with_index { |row, index|
  #    new_csv << "#{row[lat]},#{row[lon]},#{rand_name},#{index}\n" if row[lat].match(/\d+.\d*/) and row[lon].match(/\d+.\d*/)
  #  }
  #  file_path = Rails.root.join('tmp/csv', rand_name + '.csv')
  #  FileUtils.mkdir_p(File.dirname(file_path))
  #  File.open(file_path, 'w') { |f| f.write(new_csv) }
  #  csv_path = ActiveRecord::Base.connection.quote(file_path)
  #  import_sql = "COPY points(lat, lon, name, row_index) FROM '#{file_path}' DELIMITERS ',' CSV HEADER"
  #  ActiveRecord::Base.connection.execute(import_sql)
  #  trans_sql = "UPDATE points SET lat_lon = ST_SetSRID(ST_Transform(ST_SetSRID(ST_MakePoint(lon, lat), 4326), 900913), 3785) WHERE (name = '#{rand_name}')"
  #  ActiveRecord::Base.connection.execute(trans_sql)

  #  intersect_sql = "SELECT areas.id, points.id, points.lon, points.lat, points.row_index FROM areas, points WHERE (areas.layer_id = #{layer_id}) and (points.name = '#{rand_name}') and ST_Intersects(areas.polygon, points.lat_lon)"
  #  intersect_result = ActiveRecord::Base.connection.execute(intersect_sql)
  #  query_result = intersect_result.values

  #  all_areas = {}
  #  Area.where(:id => query_result.map{|r| r[0]}.uniq).each {|a| all_areas[a.id] = a}
  #  points_in_area = []
  #  all_areas.each_pair do |aid, area|
  #    entries = query_result.select { |r| r[0] == aid.to_s }
  #    points = entries.map { |e| [e[2], e[3]] }
  #    row_indexes = entries.map { |e| e[4] }
  #    marker_point = [entries[0][3], entries[0][2]]
  #    points_in_area << {
  #      :layer_id => area.layer_id,
  #      :area_id => area.id,
  #      :points => points,
  #      :pointsWithinCount => entries.length,
  #      :marker_point => marker_point,
  #      :row_indexes => row_indexes
  #    }
  #  end
  #  points_in_area

  #end
end
