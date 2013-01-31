Pointsinarea::Application.routes.draw do
  match "points" => "layers#points", :via => :post
  # FIXME: old api
  match "points/*query" => "layers#points_query"
  match "layers/:id/points_coord" => "layers#points_in_layer_coord", :via => :post#, :defaults => {:format => :json}
  # FIXME: old api
  match "layers/:layer_id/points/*query" => "layers#points_in_layer"
    #   {id => id, layer_id => layer_id, area_id => area_id, points => ( {id => id, x =>x, y =>y}, {id => id, x =>x, y =>y}, ...)}
  resources :layers do #, :defaults => {:format => 'json'} do
    collection do
      post 'upload_topojson' #, :defaults => {:format => 'json'}
      post 'upload_shapefile'#, :defaults => {:format => 'json'}
    end
  end
  match "data/upload" => "multidimensional_data#upload", :via => :get#, :defaults => {:format => :json}
  match "data/show" => "multidimensional_data#show", :via => :post#, :defaults => {:format => :json}
  #match "data/geojson" => "multidimensional_data#geojson", :via => :post
  match "layers/points_count" => "layers#points_count_in_layer", :via => :post

  match "permalink/:key" => "permalink#show"

  match "multilevel/show" => "multilevel_shapefiles#show", :via => :post#, :defaults => {:format => :json}
  match "multilevel/expand" => "multilevel_shapefiles#expand", :via => :post
  match "multilevel/findPointsInAreas" => "multilevel_shapefiles#findPointsInAreas", :via => :post

  match "api/query_points_count_of_areas" => "api#query_points_count_of_areas", :via => :post#, :defaults => {:format => :json}
  match "api/query_points_count_of_layer_areas" => "api#query_points_count_of_layer_areas", :via => :post#, :defaults => {:format => :json}
  match "api/find_layer_children" => "api#find_layer_children", :via => :post#, :defaults => {:format => :json}
  match "api/find_points_within_area" => "api#find_points_within_area", :via => :post#, :defaults => {:format => :json}

  match "api/find_filters_info" => "api#find_filters_info", :via => :post#, :defaults => {:format => :json}
  match "api/find_point_info" => "api#find_point_info", :via => :post#, :defaults => {:format => :json}

  # api doc
  mount ApiTaster::Engine => "/api-doc"
  require 'api_taster_routes'

  root :to => 'layers#index'

end
