class LayersController < ApplicationController
  before_filter :set_tolerance, :only => [:show, :points_in_layer, :points_count_in_layer]
  protect_from_forgery :except => [:create, :delete, :edit, :update, :upload_topojson, :shapefile_topojson]
  # GET /layers
  # GET /layers.json
  def index
    @layers = Layer.order(:id)
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: Rabl.render(@layers, 'layers/index', :view_path => 'app/rabl', :format => :json) }
    end
  end

  # GET /layers/1
  # GET /layers/1.json
  def show
    @layer = Layer.find(params[:id])
    areas_json = @layer.areas.map do |area|
      {area_id: area.id, polygon: area.polygon}
    end
    @result = {id: @layer.id, name: @layer.name, number_of_polygons: @layer.areas.count, areas: areas_json }

    base_url = "#{request.protocol}#{request.host_with_port}"
    permalink_hash = PermalinkController.generate_json(base_url, 'layers/show', @layer, @tolerance)
    @permalink = permalink_hash[:url]
    @data_json = permalink_hash[:data_json]

    respond_to do |format|
      format.html # show.html.erb
      format.geojson { render json: {:layer => @layer, :data_json => @data_json, :permalink => @permalink} }
      format.json { render json: {:layer => @layer, :data_json => @data_json, :permalink => @permalink} }
      format.topojson { render json: @layer.to_topojson }
    end
  end

  # GET /layers/new
  # GET /layers/new.json
  def new
    @layer = Layer.new
    respond_to do |format|
      format.html
    end
  end

  # GET /layers/1/edit
  def edit
    @layer = Layer.find(params[:id])

    respond_to do |format|
      format.html
      format.json { render json: {:name => @layer.name, :id => @layer.id} }
    end

  end

  # POST /layers
  # POST /layers.json
  def create
    @layers = return_in_correct_format(params)

    respond_to do |format|
      format.html { redirect_to layers_path, notice: 'Layer was successfully created.' }
      format.json { render json: Rabl.render(@layers, 'layers/create', :view_path => 'app/rabl', :format => :json) }
    end
    # else
    #     format.html { render action: "new" }
    #     format.json { render json: @layer.errors, status: :unprocessable_entity }
    #   end
  end



  # PUT /layers/:id
  def update
    @layer = Layer.find(params[:id])

    respond_to do |format|
      if @layer.update_with_valid_file(params[:layer])
        format.html { redirect_to @layer, notice: 'Layer was successfully updated.' }
        format.json { render json: Rabl.render(@layer, 'layers/update', :view_path => 'app/rabl', :format => :json) }
      else
        flash[:error] = "File error"
        format.html { render action: "edit" }
        format.json { render json: "File error", status: :unprocessable_entity }
      end
    end
  end

  # DELETE /layers/1
  # DELETE /layers/1.json
  def destroy
    @layer = Layer.find(params[:id])
    if @layer.destroy
      respond_to do |format|
        format.html { redirect_to layers_url }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { render action: "destroy", notice: "Can't destroy ERROR!" }
        format.json { render :json => {:error => "Could not destroy layer" },:status => 401 }
      end
    end
  end

  # post /points
  # post /points
  #
  # params:
  #   X: Latitude, Y: Longitude
  #   {
  #     [
  #     {lat => X,lon => Y,id => ID},
  #     {lat => X,lon => Y}
  #     ]
  #   }
  #
  # return:
  #   {
  #      [
  #      {layers => [layer_id,layer_id],polygons => [polygon_id,polygon_id],lat => X,lon => Y,id => ID},
  #      {layers => [layer_id,layer_id,layer_id],polygons => [polygon_id,polygon_id],lat => X,lon => Y}
  #      ]
  #    }
  def points
    #params = {
    #  :points =>
    #    [
    #      {:lat => 39.7392, :lon => -104.9842, :id => 123},
    #      {:lat => 39.7391, :lon => -104.9842},
    #      {:lat => 39.7390, :lon => -104.9842, :id => 102},
    #      {:lat => 35.6869, :lon => -105.9372, :id => 305}
    #    ]
    #}
    points = params[:points]

    tolerance = params[:tolerance].to_f if params[:tolerance].present?

    layers_including_points = []
    points.each do |point|
      areas = Area.polygon_contains_points([point], tolerance)
      layer_ids = areas.map(&:layer_id)
      layers_including_points <<
        {:layers => layer_ids, :areas => areas.map(&:id)}.merge(point)
    end

    render :json => layers_including_points
  end

  # post /layers/:id/points
  #
  # params:
  #   X: Latitude, Y: Longitude
  #   {
  #     [
  #     {lat => X,lon => Y,id => ID},
  #     {lat => X,lon => Y}
  #     ]
  #   }
  #
  # return:
  #   {
  #     :layer_id => layer_id,
  #     :areas => [
  #       {:area_id => area_id, :count => n},
  #       {:area_id => area_id, :count => n}
  #     ]
  #   }
  def points_count_in_layer_areas
    #params = {
    #  :points =>
    #    [
    #      {:lat => 39.7392, :lon => -104.9842, :id => 123},
    #      {:lat => 39.7391, :lon => -104.9842},
    #      {:lat => 39.7390, :lon => -104.9842, :id => 102},
    #      {:lat => 35.6869, :lon => -105.9372, :id => 305}
    #    ],
    #   :id => 1
    #}
    points = params[:points]
    points_count = Area.points_count_in_layer(params[:id], points, @tolerance)

    render :json => {:layer_id => params[:id].to_i, :areas => points_count}
  end

  # deprecating
  def points_in_layer_coord
    points = params[:points_coord].split(';').map do |p|
      id, lon, lat = p.split(',')
      {:id => id, :lon => lon, :lat => lat}
    end

    points_in_area = Area.contains_points_in_layer_json(params[:id].to_i, points, @tolerance)

    if params['idsonly'] && params['idsonly'] == 'true'
      points_in_area.each { |p| p.delete(:points) }
    end

    result = {
      :points_in_area => points_in_area
    }

    @layer = Layer.find(params[:id])
    @result = result

    base_url = "#{request.protocol}#{request.host_with_port}"
    permalink_hash = PermalinkController.generate_json(base_url, 'layers/points_in_layer_coord', @layer, @tolerance, @result)
    @permalink = permalink_hash[:url]
    @data_json = permalink_hash[:data_json]

    respond_to do |format|
      format.html { render 'points_in_layer' }
      format.json { render :json => {:layer => @layer, :data_json => @data_json, :permalink => @permalink} }
    end
  end



  # FIXME: old api
  # /layers/:layer_id/points/:id,:lon,:lat
  # /layers/:layer_id/points/:id1,:lon1,:lat1;:id2,:lon2,:lat2
  # /layers/:layer_id/points/:id,:lon,:lat.json
  # /layers/:layer_id/points/:id1,:lon1,:lat1;:id2,:lon2,:lat2.json
  def points_in_layer
    # request.path => "/points/123,-74.006605,40.714623" or "/points/123,-74.006605,40.714623.json"
    json_match = request.path.match('.json')
    query = request.path.gsub('.json', '').split("/").last.split(";")
    points = query.inject([]) do |r, _|
      id, lon, lat = _.split(",")
      r << {:id => id, :lon => lon, :lat => lat}
    end

    points_in_area = Area.contains_points_in_layer_json(params[:layer_id].to_i, points, @tolerance)

    if params['idsonly'] && params['idsonly'] == 'true'
      points_in_area.each { |p| p.delete(:points) }
    end

    result = {
      :points_in_area => points_in_area
    }

    @layer = Layer.find(params[:layer_id])
    @result = result

    base_url = "#{request.protocol}#{request.host_with_port}"
    permalink_hash = PermalinkController.generate_json(base_url, 'layers/points_in_layer', @layer, @tolerance, @result)
    @permalink = permalink_hash[:url]
    @data_json = permalink_hash[:data_json]


    if json_match
      render json: @result
    else
      render 'points_in_layer'
    end
  end


  # Ajax query to get count in the areas of the layer based on some points
  def points_count_in_layer
    result = {:points_in_area => [], :points_count_arr => [], :areas_id => [], :count_id_hash => {}}
    if(params[:points].blank?)
      render :json => result.to_json if params[:points].blank?
    else
      points = params[:points].values.map do |v|
        {:id => params[:layer_id], :lat => v[0], :lon => v[1]}
      end

      points_in_area = Area.contains_points_in_layer_json(params[:layer_id].to_i, points, @tolerance)
      points_in_area.each {|p| p.delete(:points)}
      area_ids = points_in_area.map{|p| p[:area_id]}

      result = { :points_in_area => points_in_area, :points_count_arr => points_in_area.map{|p| p[:pointsWithinCount]}, :areas_id => area_ids, :count_id_hash => points_in_area.map{|p| {p[:area_id] => p[:pointsWithinCount]}}.inject(:merge) }

      render :json => JSON.generate(result)
    end
  end


  def return_in_correct_format(params)
    return false if params[:layer][:file].blank?
    format = File.extname(params[:layer][:file].original_filename)

    case format
    when '.geojson'
      return create_with_geojson
    when '.geo.json'
      return create_with_geojson
    when '.json'
      return create_with_topojson
    when '.zip'
      return create_with_shapefile
    else
      return false
    end
  end

  def create_with_geojson
    @layer = Layer.new(params[:layer])
    @layer.save
    [@layer]
  end

  def create_with_topojson
    upload = params[:layer][:file]
    # The comparing method should be improved
    if upload.class != ActionDispatch::Http::UploadedFile
      if upload[:tempfile].class == ActionDispatch::Http::UploadedFile
        upload = upload[:tempfile]
      else
        return true
      end
    end
    if upload
      @layers = Layer.create_from_topojson(params[:layer])
    end
    @layers
  end

  def create_with_shapefile
    @layers = Layer.upload_shapefile(params[:layer])
    if @layers and @layers.map(&:save).all?
      @layers[1..-1].each_with_index do |l, i|
        l.update_attributes({:parent_id => @layers[i].id})
      end
    end
    @layers
  end


  # Deprecated
  def upload_topojson
    upload = params[:layer][:file]
    # The comparing method should be improved
    if upload.class != ActionDispatch::Http::UploadedFile
      if upload[:tempfile].class == ActionDispatch::Http::UploadedFile
        upload = upload[:tempfile]
      else
        return true
      end
    end
    if upload
      @layers = Layer.create_from_topojson(params[:layer])
      respond_to do |format|
        format.html { redirect_to layers_path, notice: "#{@layers.size} layers created" }
        format.json { render json: Rabl.render(@layers, 'layers/upload_topojson', :view_path => 'app/rabl', :format => :json) }
      end
    else
      respond_to do |format|
        format.html { render action: "new", notice: 'Topojson uploading ERROR!' }
        format.json { render json: @layers.map(&:errors), status: :unprocessable_entity }
      end
    end
  end
  # Deprecated
  def upload_shapefile
     @layers = Layer.upload_shapefile(params[:layer])

    respond_to do |format|
      if @layers and @layers.map(&:save).all?
        @layers[1..-1].each_with_index { |l, i|
          l.update_attributes({:parent_id => @layers[i].id})
        }
        format.html { redirect_to layers_path, notice: 'Layer was successfully created.' }
        format.json { render json: Rabl.render(@layers, 'layers/upload_topojson', :view_path => 'app/rabl', :format => :json) }
      else
        format.html { render action: "new", notice: 'Shapefile uploading ERROR!' }
        format.json { render json: @layers.map(&:errors), status: :unprocessable_entity }
      end
    end
  end

end
