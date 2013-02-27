require 'spec_helper'

describe LayersController, '#create', :type => :controller do
  render_views
  describe 'geojson' do
    before(:each) do
      @layer = {
          :name => "",
          :file => FactoryGirlHelpers.upload_geojson_file }
    end

    it "should change Layer by count  by 1" do
      lambda do
        post :create, { :layer => @layer, :format => :json}
      end.should change(Layer, :count).by(1)
    end

    it "should return valid json data" do
      post :create, { :layer => @layer, :format => :json}
      valid_response = {layers: [{:id => 1,   :name => "manhattan_geojson.geojson",     :number_of_polygons => 1}] }
      response.body.should_not eq({})
      response.body.should eq(valid_response.to_json)
    end
  end


  describe 'upload_shapefile' do
    before(:each) do
      @layer = {
        :name => "",
        :file => FactoryGirlHelpers.upload_shapefile }
    end

    it "should change Layer by count  by 1" do
      lambda do
        post :create, { :layer => @layer, :format => :json }
      end.should change(Layer, :count).by(1)
    end

    it "should return valid json data" do
      post :create, { :layer => @layer, :format => :json}
      valid_response = {layers: [{:id => 1,   :name => "#{@layer[:name]}_tgr36061msa00",     :number_of_polygons => 1}] }
      response.body.should_not eq({})
      response.body.should eq(valid_response.to_json)
    end
  end

  describe 'upload_topojson' do
    before(:each) do
      @layer = {
        :name => "",
        :file => FactoryGirlHelpers.upload_topojson_file }
    end

    it "should change Layer by count  by 1" do
      lambda do
        post :create, { :layer => @layer, :format => :json}
      end.should change(Layer, :count).by(1)
    end

    it "should return valid json data" do
      post :create, { :layer => @layer, :format => :json}
      valid_response = {layers: [{:id => 1,   :name => "Manhattan_topojson.json",     :number_of_polygons => 1}] }
      response.body.should_not eq({})
      response.body.should eq(valid_response.to_json)
    end
  end
end
