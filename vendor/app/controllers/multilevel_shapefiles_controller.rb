class MultilevelShapefilesController < ApplicationController
  before_filter :set_tolerance, :only => [:show]
protect_from_forgery :except => [:show, :upload]
  def show
    unless params[:csv_file]
      flash[:warning] = "Please choose your csv file"
      redirect_to request.env['HTTP_REFERER']
    else
      csv_file = params[:csv_file]
      if !params[:csv_file].respond_to?(:path)
        if params[:csv_file][:tempfile].respond_to?(:path)
          csv_file = params[:csv_file][:tempfile]
        else
          return true
        end
      end
      # get the header and the body as hash
      @layer = Layer.find(params[:layer_id])

      csv_handler = CsvHandler.new csv_file.path

      # find the lat and lon
      lat, lon = * csv_handler.get_xy_str(params[:lon], params[:lat])

      if(lat.length != 1 or lon.length != 1)
        redirect_to data_upload_path(:header => csv_handler.header)
      else
        # find the rows which are suitable for attributes selection
        csv_handler.find_filters

        # get the points_in_area ([{:layer_id, :area_id, :points, :pointsWithinCount, :row_indexes}])
        query_result = Point.csv_to_temp_points(csv_handler, @layer.child.id)
        points_in_area = query_result[:points_in_area]

        points_with_index = csv_handler.points_with_index

        result = [{:layer_id => @layer.id, :area_id => @layer.areas[0].id, :pointsWithinCount => points_in_area.inject(0){ |sum, p| sum + p[:pointsWithinCount] }}]

        @result = { :points_in_area => result, :points_table_name => query_result[:table_name], :points_with_index => points_with_index, :filters => csv_handler.filters }

        # generate permalink the the json data
        base_url = "#{request.protocol}#{request.host_with_port}"
        permalink_hash = PermalinkController.generate_json(base_url, 'multilevel_shapefiles/show', @layer, @tolerance, @result)
        @permalink = permalink_hash[:url]
        @data_json = permalink_hash[:data_json]

        respond_to do |format|
          format.html { render :show }
          format.json { render :json => {:data_json => @data_json, :permalink => @permalink} }
        end
      end
    end
  end

  def geojson
    geojson = params[:geojson].read
    @geojson = geojson
    render 'geojson'
  end
end
