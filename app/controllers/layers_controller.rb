class LayersController < ApplicationController
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

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @layer }
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
      if @layer.save
        format.html { redirect_to @layer, notice: 'Layer was successfully created.' }
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

    lon_lats = points.map{|point| [point[:lon], point[:lat]] }
    areas = Area.polygon_contains_points(lon_lats)
    points_in_area = []
    areas.each do |area|
      points = area.filter_including_points(points)
      area_as_json = {
        :layer_id => area.layer_id,
        :area_id  => area.id,
        :points   => points,
        :count    => points.count
      }
      points_in_area << area_as_json
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
  def points_in_layer
    # request.path => "/points/123,-74.006605,40.714623"
    query = request.path.split("/").last.split(";")
    points = query.inject([]) do |r, _|
      id, lon, lat = _.split(",")
      r << {:id => id, :lon => lon, :lat => lat}
    end

    # lon_lats = points.map{|point| [point[:lon], point[:lat]] }
    points_in_area = Area.contains_points_in_layer_json(params[:layer_id].to_i, points)

    result = {
      :points_in_area => points_in_area
    }

    # points_in_area = (
    #   {id => id, layer_id => layer_id, area_id => area_id, points => ( {id => id, x =>x, y =>y}, {id => id, x =>x, y =>y}, ...)},
    #   {id => id, layer_id => layer_id, area_id => area_id, points => ( {id => id, x =>x, y =>y}, {id => id, x =>x, y =>y}, ...)}
    # )
    render :json => result
  end
end
