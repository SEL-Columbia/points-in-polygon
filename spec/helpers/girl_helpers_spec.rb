require 'spec_helper'

describe 'FactoryGirlHelpers' do

  it 'upload_geojson_file should return file in location' do
    test_path = Rails.root.join("spec/fixtures/geojson/manhattan_geojson.geojson").to_s
    FactoryGirlHelpers.upload_geojson_file.path.should eq test_path
  end
  it 'upload_geojson_file("ny_state_geojson.geojson") should return file in location' do
    test_path = Rails.root.join("spec/fixtures/geojson/ny_state_geojson.geojson").to_s
    FactoryGirlHelpers.upload_geojson_file("ny_state_geojson.geojson").path.should eq test_path
  end

  it 'upload_topojson_file should return file in location' do
    test_path = Rails.root.join("spec/fixtures/topojson/manhattan_topojson.json").to_s
    FactoryGirlHelpers.upload_topojson_file.path.should eq test_path
  end
  it 'upload_topojson_file("ny_state_topojson.json") should return file in location' do
    test_path = Rails.root.join("spec/fixtures/topojson/ny_state_topojson.json").to_s
    FactoryGirlHelpers.upload_topojson_file("ny_state_topojson.json").path.should eq test_path
  end

  it 'upload_shape_file should return file in location' do
    test_path = Rails.root.join("spec/fixtures/shapefile/manhattan_shapefile.zip").to_s
    FactoryGirlHelpers.upload_shapefile.path.should eq test_path
  end
  it 'upload_shape_file("manhattan_districts_shapefile.zip") should return file in location' do
    test_path = Rails.root.join("spec/fixtures/shapefile/manhattan_districts_shapefile.zip").to_s
    FactoryGirlHelpers.upload_shapefile('manhattan_districts_shapefile.zip').path.should eq test_path
  end
end
