class MultidimensionalDataController < ApplicationController
  before_filter :set_tolerance, :only => [:show]
  protect_from_forgery :except => [:show, :upload]
  def upload
    if params[:header]
      @header = params[:header]
      flash[:warning] ||= "The longitude or latitude can't be found automatically, please choose them by hand and upload again"
    end
    @layers = Layer.order("name")
    options_multidata = @layers.map { |l| [l.name, l.id] }
    options_multilevel = @layers.select {|l| l.parent.blank? and ! l.child.blank?}.map { |l| [l.name, l.id] }

    respond_to do |format|
      format.html
      format.json { render :json => {:options_multidata => options_multidata, :options_multilevel => options_multilevel} }
    end
  end

  def show
    binding.pry
    unless params[:csv_file]
      flash[:warning] = "Please choose your csv file"
      redirect_to request.env['HTTP_REFERER']
      return
    end
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
      return
    end
    # find the rows which are suitable for attributes selection
    csv_handler.find_filters

    layer_id = (params[:multilevel] and !@layer.child.blank?) ? @layer.child.id : params[:layer_id]
    # get the points_in_area ([{:layer_id, :area_id, :points, :pointCount, :row_indexes}])
    query_result = Point.csv_to_temp_points(csv_handler, layer_id)

    points_with_index = csv_handler.points_with_index

    @result = {:points_in_area => query_result[:points_in_area], :points_table_name => query_result[:table_name], :points_with_index => points_with_index, :filters => csv_handler.filters}

    request_path = params[:multilevel] ? 'multilevel_shapefiles/show' : 'multidimensional_data/show'

    # generate permalink the the json data
    base_url = "#{request.protocol}#{request.host_with_port}"
    permalink_hash = PermalinkController.generate_json(base_url, request_path, @layer, @tolerance, @result)
    @permalink = permalink_hash[:url]
    @data_json = permalink_hash[:data_json]

    respond_to do |format|
      format.html { render :template => request_path }
      format.json { render :json => {:data_json => @data_json, :permalink => @permalink} }
    end
  end

  def geojson
    geojson = params[:geojson].read
    @geojson = geojson
    render 'geojson'
  end
end
