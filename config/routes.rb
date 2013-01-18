Pointsinarea::Application.routes.draw do
  match "points/*query" => "layers#points"
  match "layers/:layer_id/points/*query" => "layers#points_in_layer"
  resources :layers do
    collection do
      post 'upload_topojson'
      post 'upload_shapefile'
    end
  end
  match "data/upload" => "multidimensional_data#upload"
  match "data/show" => "multidimensional_data#show", :via => :post
  #match "data/geojson" => "multidimensional_data#geojson", :via => :post
  match "layers/points_count" => "layers#points_count_in_layer", :via => :post

  match "permalink/:key" => "permalink#show"

  match "multilevel/show" => "multilevel_shapefiles#show", :via => :post
  match "multilevel/expand" => "multilevel_shapefiles#expand", :via => :post
  match "multilevel/findPointsInAreas" => "multilevel_shapefiles#findPointsInAreas", :via => :post

  root :to => 'layers#index'
end
