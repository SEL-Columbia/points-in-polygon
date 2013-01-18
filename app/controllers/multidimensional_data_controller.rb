class MultidimensionalDataController < ApplicationController
  before_filter :set_tolerance, :only => [:show]

  def upload
    if params[:header]
      @header = params[:header]
      flash[:warning] ||= "The longitude or latitude can't be found automatically, please choose them by hand and upload again"
    end
    @layers = Layer.order("name")
  end

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

        # get the points_in_area ([{:layer_id, :area_id, :points, :pointCount, :row_indexes}])
        points_in_area = Point.csv_to_temp_points(body, lat, lon, params[:layer_id])[:points_in_area]

        @result = {:points_in_area => points_in_area}

        # generate permalink the the json data
        base_url = "#{request.protocol}#{request.host_with_port}"
        permalink_hash = PermalinkController.generate_json(base_url, 'multidimensional_data/show', @layer, @tolerance, @result, @csv_rows)
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
end
