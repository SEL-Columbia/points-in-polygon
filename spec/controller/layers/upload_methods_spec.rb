require 'spec_helper'

describe LayersController, :type => :controller do
  render_views


  describe 'upload_shapefile' do
    before(:each) do
      @layer = {
        :name => "",
        :file => FactoryGirlHelpers.upload_shapefile }
    end

    it "should change Layer by count  by 1" do
      lambda do
        post :upload_shapefile, { :layer => @layer, :format => :json }
      end.should change(Layer, :count).by(1)
    end

    it "should return valid json data" do
      post :upload_shapefile, { :layer => @layer, :format => :json}
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
        post :upload_topojson, { :layer => @layer, :format => :json}
      end.should change(Layer, :count).by(1)
    end

    it "should return valid json data" do
      post :upload_topojson, { :layer => @layer, :format => :json}
      valid_response = {layers: [{:id => 1,   :name => "Manhattan_topojson.json",     :number_of_polygons => 1}] }
      response.body.should_not eq({})
      response.body.should eq(valid_response.to_json)
    end
  end
end
