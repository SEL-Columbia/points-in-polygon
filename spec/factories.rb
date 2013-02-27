FactoryGirl.define do
  factory :layer do
    name ""
    trait :geojson do
      file FactoryGirlHelpers.upload_geojson_file
    end
  end
end


# This might come in handys if i refactor
# trait :topojson do
# geo_file FactoryGirlHelpers.upload_topojson_file
# end
# trait :shapefile do
# geo_file FactoryGirlHelpers.upload_shapefile
# end
