require 'spec_helper'

describe LayersController, '#index', :type => :controller do
  render_views

  before(:each) do
    FactoryGirl.create :layer, :geojson, {
      :name => "",
      :file => FactoryGirlHelpers.upload_geojson_file }
    FactoryGirl.create :layer, :geojson, {
      :name => 'Important Cities',
      :file => FactoryGirlHelpers.upload_geojson_file }
    FactoryGirl.create :layer, :geojson, {
      :name => "",
      :file => FactoryGirlHelpers.upload_geojson_file('ny_state_geojson.geojson') }

    @valid_response = {layers: [
                                {:id => 1,   :name => "manhattan_geojson.geojson",     :number_of_polygons => 1},
                                {:id => 2,   :name => "Important Cities",             :number_of_polygons => 1},
                                {:id => 3,   :name => "ny_state_geojson.geojson",     :number_of_polygons => 1}
                               ]}

  end

  it "should return specific data in JSON format" do
    get :index, :format => :json
    response.header['Content-Type'].should include 'application/json; charset=utf-8'
    response.body.should_not eq({});
    response.body.should eq(@valid_response.to_json);
    Layer.all.count.should eq 3
  end

  it "should contain specific information" do
    get :index, :format => :html

    Layer.all.count.should eq 3
    response.should render_template("index")
    response.code.should eq '200'
    response.body.should =~ /manhattan_geojson.geojson/m
    response.body.should =~ /Important Cities/m
    response.body.should =~ /ny_state_geojson.geojson/m
    response.header['Content-Type'].should include 'text/html; charset=utf-8'
  end
end
