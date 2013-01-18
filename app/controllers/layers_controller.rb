class LayersController < ApplicationController
  before_filter :set_tolerance, :only => [:show, :points_in_layer, :points_count_in_layer]

  # GET /layers
  # GET /layers.json
  def index
    @layers = Layer.all

    respond_to do |format|
      format.html # index.html.erb
      # example output:
      # {"layers":[{"id":14,"name":"coutries","number_of_polygons":279}]}
      format.json { render json: {layers: @layers.map {|layer| {id: layer.id, name:layer.name, number_of_polygons: layer.areas.count}}} }
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
      format.json { render json: @result }
      format.topojson { render json: @layer.to_topojson }
    end
  end

  # GET /layers/new
  # GET /layers/new.json
  def new
    @layer = Layer.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @layer }
    end
  end

  # GET /layers/1/edit
  def edit
    @layer = Layer.find(params[:id])
  end

  # POST /layers
  # POST /layers.json
  def create
    @layer = Layer.new(params[:layer])

    respond_to do |format|
      if @layer and @layer.save
        format.html { redirect_to layers_path, notice: 'Layer was successfully created.' }
        format.json { render json: @layer, status: :created, location: @layer }
      else
        format.html { render action: "new" }
        format.json { render json: @layer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /layers/1
  # PUT /layers/1.json
  def update
    @layer = Layer.find(params[:id])

    respond_to do |format|
      if @layer.update_attributes(params[:layer])
        format.html { redirect_to @layer, notice: 'Layer was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @layer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /layers/1
  # DELETE /layers/1.json
  def destroy
    @layer = Layer.find(params[:id])
    @layer.destroy

    respond_to do |format|
      format.html { redirect_to layers_url }
      format.json { head :no_content }
    end
  end

  # /points/:id,:lon,:lat
  # /points/:id1,:lon1,:lat1;:id2,:lon2,:lat2
  def points
    # request.path => "/points/123,-74.006605,40.714623"
    query = request.path.split("/").last.split(";")
    points = query.inject([]) do |r, _|
      id, lon, lat = _.split(",")
      r << {:id => id, :lon => lon, :lat => lat}
    end

    tolerance = params[:tolerance].to_f if params[:tolerance].present?

    lon_lats = points.map{|point| [point[:lon], point[:lat]] }
    areas = Area.polygon_contains_points(lon_lats, tolerance)
    points_in_area = []
    areas.each do |area|
      points = area.filter_including_points(points)
      area_as_json = {
        :layer_id => area.layer_id,
        :area_id  => area.id,
        :points   => points,
        :pointsWithinCount    => points.count
      }
      points_in_area << area_as_json
    end

    if params['idsonly'] && params['idsonly'] == 'true'
      points_in_area.each { |p| p.delete(:points) }
    end

    result = {
      :points_in_area => points_in_area
    }

    # points_in_area = (
    #   {id => id, layer_id => layer_id, area_id => area_id, points => ( {id => id, x =>x, y =>y}, {id => id, x =>x, y =>y}, ...)},
    #   {id => id, layer_id => layer_id, area_id => area_id, points => ( {id => id, x =>x, y =>y}, {id => id, x =>x, y =>y}, ...)}
    # )
    render :json => result
  end



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

    # points_in_area = (
    #   {id => id, layer_id => layer_id, area_id => area_id, points => ( {id => id, x =>x, y =>y}, {id => id, x =>x, y =>y}, ...)},
    #   {id => id, layer_id => layer_id, area_id => area_id, points => ( {id => id, x =>x, y =>y}, {id => id, x =>x, y =>y}, ...)}
    # )
    # render :json => result
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
    start_time = Time.now
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
    end_time = Time.now
    elapsed_time = (end_time.to_f * 1000.0).to_i - (start_time.to_f * 1000.0).to_i
    p elapsed_time

  end

  def upload_topojson
    upload = params[:layer][:upload]
    created = Layer.create_from_topojson(upload) if upload
    redirect_to layers_path, notice: "#{created.size} layers created"
  end

  def upload_shapefile
     @layers = Layer.upload_shapefile(params[:layer])
     
    respond_to do |format|
      if @layers and @layers.map(&:save).all?
        @layers[1..-1].each_with_index { |l, i| 
          l.update_attributes({:parent_id => @layers[i].id}) 
        }
        format.html { redirect_to layers_path, notice: 'Layer was successfully created.' }
      else
        format.html { render action: "new", notice: 'Shapefile uploading ERROR!' }
      end
    end
  end

end
