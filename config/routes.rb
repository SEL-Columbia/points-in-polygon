Pointsinarea::Application.routes.draw do
  match "points/*query" => "layers#points"
  match "layers/:layer_id/points/*query" => "layers#points_in_layer"
  resources :layers

  root :to => 'layers#index'
end
