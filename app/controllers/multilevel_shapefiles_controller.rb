class MultilevelShapefilesController < ApplicationController
  before_filter :set_tolerance, :only => [:show]

  def show
    unless params[:csv_file]
      flash[:warning] = "Please choose your csv file"
      redirect_to request.env['HTTP_REFERER']
    else
      # get the header and the body as hash
      @layer = Layer.find(params[:layer_id])
      csv_data = CSV.read(params[:csv_file].path)
      header = csv_data[0]
      body = csv_data[1..-1].map do |row|
        Hash[header.zip(row)]
      end

      # find the lat and lon
      lat = header.select{|h| h and h.match 'lat'}
      lon = header.select{|h| h and h.match 'lon'}
      lon = [params[:lon]] if params[:lon]
      lat = [params[:lat]] if params[:lat]
      if(lat.length != 1 or lon.length != 1)
        redirect_to data_upload_path(:header => header)
      else
        # find the rows which are suitable for attributes selection
        lat, lon = lat[0], lon[0]
        unique = Hash.new({})
        header.each_with_index do |col, index|
          unique[col] = Hash.new(0)
          body.each {|item| unique[col][item[col]] += 1}
        end
        header = header.select{|col| unique[col].length < Math.sqrt(body.length)}
        header.push(lat).push(lon)
        @csv_rows = [header].push(body)

        # get the points_in_area ([{:layer_id, :area_id, :points, :pointsWithinCount, :row_indexes}])
        query_result = Point.csv_to_temp_points(body, lat, lon, @layer.child.id)
        points_in_area = query_result[:points_in_area]

        session[:table_name] = query_result[:table_name]
      
        result = [{:layer_id => @layer.id, :area_id => @layer.areas[0].id, :pointsWithinCount => points_in_area.inject(0){ |sum, p| sum + p[:pointsWithinCount] }}]

        @result = { :points_in_area => result }

        # generate permalink the the json data
        base_url = "#{request.protocol}#{request.host_with_port}"
        permalink_hash = PermalinkController.generate_json(base_url, 'multilevel_shapefiles/show', @layer, @tolerance, @result, @csv_rows)
        @permalink = permalink_hash[:url]
        @data_json = permalink_hash[:data_json]

        render 'show'
      end
    end
  end

  def geojson
    geojson = params[:geojson].read
    @geojson = geojson
    render 'geojson'
  end

  def expand
    @layer = Layer.find(params[:layer_id].to_i)
    @area = Area.find(params[:area_id].to_i)
    @level = params[:level].to_i
    if @level >= 0
      result = getChildren @level
    else
      table_name = session[:table_name]
      point_total_count = ActiveRecord::Base.connection.execute("SELECT points.count FROM #{table_name} as points").values[0]
      result = {:children => {@area.id => JSON.parse(@area.unproject_exterior_ring)}, :counts => {@area.id => point_total_count}, :points => [], :all_points_existed => {}}
    end
    result[:old_area_id] = params[:area_id]
    level_info = {}
    unless @layer.child.blank?
      level_info[:layer_id] = @level >= 0 ? @layer.child.id : params[:layer_id]
      level_info[:level] = @level + 1
    else
      level_info[:layer_id] = params[:layer_id]
      level_info[:level] = params[:level]
    end
    level_info[:area_id] = @area.id
    result[:level_info] = level_info
    
    render :json => JSON.generate(result)
  end

  def findPointsInAreas
    area_ids = params['area_ids'];
    row_indexes = params['points'];

    result = getAreas area_ids, row_indexes

    render :json => JSON.generate(result)
  end

  protected

    def getAreas(area_ids, row_indexes)
      counts = {}
      table_name = session[:table_name]

      #if row_indexes.blank?
      #  return {:counts => []}
      #end
      if row_indexes.blank?
        return {:counts => []}
      end

      sql = "SELECT dumped_areas.area_id, count(points) FROM (SELECT areas.id as area_id, (ST_Dump(areas.multipolygon)).geom as multi_geom, areas.polygon as poly_geom FROM areas WHERE (areas.id IN (#{area_ids * ','}))) as dumped_areas, #{table_name} as points WHERE (points.row_index in (#{row_indexes * ','})) AND ((dumped_areas.poly_geom is not NULL and ST_Intersects(dumped_areas.poly_geom, points.lon_lat)) or (dumped_areas.multi_geom is not NULL and ST_Intersects(dumped_areas.multi_geom, points.lon_lat))) GROUP BY dumped_areas.area_id"
      query_result = ActiveRecord::Base.connection.execute(sql).values
      query_result.each { |i| counts[i[0]] = i[1].to_i }     

      return {:counts => counts}

    end

    def getChildren(level)
      children = {}
      counts = Hash.new(0)
      points = []
      all_points_existed = {}
      table_name = session[:table_name]

      unless @layer.child.blank?
        area_ids = @layer.child.areas.select(:id).where(:parent_id => @area.level_id).map(&:id)
        area_points_sql = "SELECT dumped_areas.area_id, points.row_index FROM (SELECT areas.id as area_id, (ST_Dump(areas.multipolygon)).geom as multi_geom, areas.polygon as poly_geom FROM areas WHERE (areas.id IN (#{area_ids * ','}))) as dumped_areas, #{table_name} as points WHERE (dumped_areas.poly_geom is not NULL and ST_Intersects(dumped_areas.poly_geom, points.lon_lat)) or (dumped_areas.multi_geom is not NULL and ST_Intersects(dumped_areas.multi_geom, points.lon_lat))"
        area_points = ActiveRecord::Base.connection.execute(area_points_sql).values

        #area_points.values.each { |v| counts[v[0]] = v[1].to_i }
        area_points.each do |i|
          counts[i[0]] += 1
          all_points_existed[i[0]] = [] if all_points_existed[i[0]].blank?
          all_points_existed[i[0]] << i[1] if @layer.child.child.blank? or level == 0
        end

        Area.where(:id => area_ids).select("id, unproject_exterior_ring").map { |r| children[r.id] = JSON.parse(r.unproject_exterior_ring) }
      else
        area_points_sql = "SELECT points.row_index FROM (SELECT areas.id as area_id, (ST_Dump(areas.multipolygon)).geom as multi_geom, areas.polygon as poly_geom FROM areas WHERE areas.id = #{@area.id}) as dumped_areas, #{table_name} as points WHERE (dumped_areas.poly_geom is not NULL and ST_Intersects(dumped_areas.poly_geom, points.lon_lat)) or (dumped_areas.multi_geom is not NULL and ST_Intersects(dumped_areas.multi_geom, points.lon_lat))"
        area_points = ActiveRecord::Base.connection.execute(area_points_sql)
        
        area_points.values.each { |v| points << v[0] }
      end

      return {:children => children, :counts => counts, :points => points, :all_points_existed => all_points_existed}
    end
end
