class Point < ActiveRecord::Base
  attr_accessible :name, :lat, :lon, :lat_lon

  def self.csv_to_temp_points(csv_handler, layer_id)
    table_name = csv_handler.csv_to_db

    # add a geometry column to the temp table
    add_geometry_sql = "SELECT AddGeometryColumn('public', '#{table_name}', 'lon_lat', 3785, 'POINT', 2)"
    self.connection.execute(add_geometry_sql)

    # update the geometry column in the table
    trans_sql = "UPDATE #{table_name} SET lon_lat = ST_SetSRID(ST_Transform(ST_SetSRID(ST_MakePoint(lon, lat), 4326), 900913), 3785)"
    self.connection.execute(trans_sql)

    # create indexes to the geometry column
    index_sql = "CREATE INDEX #{table_name}_lon_lat ON #{table_name} USING GIST ( lon_lat )"
    ActiveRecord::Base.connection.execute(index_sql)

    begin
      # TODO: need to be refactored using the SqlGenerator
      intersect_sql_single = "SELECT areas.id, count(points) FROM areas, #{table_name} as points WHERE (areas.layer_id = #{layer_id}) AND areas.polygon is not NULL and ST_Intersects(areas.polygon, points.lon_lat) GROUP BY areas.id"
      intersect_result_single = ActiveRecord::Base.connection.execute(intersect_sql_single)
      intersect_sql_multi = "SELECT dumped_areas.area_id, count(points) FROM (SELECT areas.id as area_id, (ST_Dump(areas.multipolygon)).geom as multi_geom FROM areas WHERE (areas.layer_id = #{layer_id})) as dumped_areas, #{table_name} as points WHERE dumped_areas.multi_geom is not NULL and ST_Intersects(dumped_areas.multi_geom, points.lon_lat) GROUP BY dumped_areas.area_id"
      intersect_result_multi = ActiveRecord::Base.connection.execute(intersect_sql_multi)
      query_result = intersect_result_multi.values.concat(intersect_result_single.values)
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
      area_entries[entry[0]] = entry[1]
    end

    # put the data to the points_in_area and return it
    all_areas = {}
    Area.where(:id => query_result.map{|r| r[0]}.uniq).each {|a| all_areas[a.id] = a}
    points_in_area = []
    all_areas.each_pair do |aid, area|
      #entries = area_entries[aid.to_s]
      #points = entries.map { |e| [e[1], e[2]] }
      #row_indexes = entries.map { |e| e[3] }
      points_in_area << {
        :layer_id => area.layer_id,
        :area_id => area.id,
        #:points => points,
        :pointsWithinCount => area_entries[aid.to_s].to_i,
        #:row_indexes => row_indexes
      }
    end
    {:points_in_area => points_in_area, :table_name => table_name}
  end
end
