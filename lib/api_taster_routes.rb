module ApiTaster
  class Route
    class << self
      # we dont need Missing Route Definitions Detection
      # def missing_definitions
      #   []
      # end

      # we dont need Obsolete / Mismatched Route Definitions Detection
      # def obsolete_definitions
      #         []
      #       end
    end
  end
end

ApiTaster.routes do

  desc <<HERE
    Layers list add .json extension for json output
HERE
  get '/layers', {}

  desc <<HERE
    Layer creation, supply a geojson file in post
HERE
  post '/layers', {
    :layer => {
      :name => 'layer',
      :geo_file => :file
    }
  }

  desc <<HERE
    Create layer, supply a shapefile in post
HERE
  post '/layers/upload_shapefile', {
    :layer => {
      :name => 'shapefile-layer',
      :geo_file => :file
    }
  }

  desc <<HERE
    Create layer, supply a topojson file in post
HERE
  post '/layers/upload_topojson', {
    :layer => {
      :name => 'topojson-layer',
      :upload => :file
    }
  }

  desc <<HERE
    Display layer as - provide json, topojson as an extension to render 
HERE
  get '/layers/:id', {
    :id => 38
  }

  desc <<HERE
    Edit a layer meta data
HERE
  get '/layers/:id/edit', {
    :id => 38
  }

  desc <<HERE
    update a layer, supply a geojson file in post
HERE
  put '/layers/:id', {
    :id => 38,
    :geo_file => :file
  }

  desc <<HERE
    Delete a layer
HERE
  delete '/layers/:id', {
    :id => 39
  }

  desc <<HERE
    find polygons in a layer containing points - with counts, supply coordinates & layerid
HERE
  post '/layers/:id/points_coord', {
    :id => 27,
    :points_coord => "123,-104.9842,39.7392;101,-104.9842,39.7391;102,-104.9842,39.7390;801,-105.9372,35.6869"
  }

  desc <<HERE
     Query a count of points in given areas

     == Parameters:
     params::
       A hash with keys areas_ids, points, table_name
       - areas_ids
         An array including all areas you want to query
       - points
         An array including all row_indexes of points you want to query
       - table_name
         points table name (all points are saved to a tmp db table when importing csv)

     == Returns:
     A hash json with area_id as key and count as value
     {area_id1 => count1, area_id2 => count2}
HERE
  post '/api/query_points_count_of_areas', {
    :area_ids => [980,3981,3982,3983,3984,3985,3986,3987,3988,3989,3990,
      3991,3992,3993,3994,3995,3996,3997,3998,3999,4000,4001,4002,4003,4004],
    :points => [12240,12323,12325,12331,12332,12357,12366,12435,12436,12437,12439,
      12440,12441,12442,12445,12447,12448,12449,12450,12451,12452,12453,12456,12458,12460,
      12461,12463,12466,12467,12510,12535,12536,12538,12541,12997,12998,12999,
      13079,13080,13081,13083,13084,13086,13087,13088,13089,13090,13107,13110,
      13112,13114,13116,13126,13127,13128,13129,13130,13134,13141,13149,13163,
      13164,13165,13168,13169,13355,13361,13365,13366,13369,13370],
    :table_name => "points2df59f2cb3390905eed5"
  }

  desc <<HERE
     Query points in the polygons on a given layer

     == Parameters:
     params::
       A hash with keys layer_id, points, table_name
       - layer_id
         Layer with the id includes some areas
       - points
         A array including indexes of points
       - table_name
       points table name (all points are saved to a tmp db table when importing csv)

     == Returns:
     A hash with area_id as key and count as value
     {area_id1 => count1, area_id2 => count2}
HERE
  post '/api/query_points_count_of_layer_areas', {
    :layer_id =>  25,
    :points => [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30],
    :table_name => "points1ea95c655503def1a431"
  }

  desc <<HERE
     Find areas with counts which belong to the polygon on a specified layer
     (when in the multilevel layers, click one area to show the children)

     == Parameters:
     params::
       A hash with keys layer_id, area_id, table_name
       - layer_id
         The layer includes the area and can be used to judge is
         this level is penultimate
       - area_id
         The area is used to query its children
       - table_name
       points table name (all points are saved to a tmp db table when importing csv)

     == Returns:
     A hash with children, counts, points, is_penultimate, layer_id
     {
       :children =>
         {area_id1 => unproject_exterior_ring, ...},
       :counts =>
         {area_id1 => count1, area_id2 => count2 ...},
       :points =>
         {area_id1 => [p1, p2, ..], area_id2 => [p3, p4, ..]},
         (points are in area)
       :is_penultimate => true/false,
       :layer_id => the id of given layer's child
      }
HERE
  post '/api/find_layer_children', {
    :layer_id => 25,
    :area_id => 3408,
    :table_name => "points2df59f2cb3390905eed5"
  }

  desc <<HERE
     Find all points in the given area

     == Parameters:
     params::
       A hash with keys area_id, table_name
       - area_id
         The area used to be query
       - table_name
     points table name (all points are saved to a tmp db table when importing csv)

     == Returns:
     An array including the indexes of points belonging to the area
     [p1, p2, p3 ...]
HERE
  post '/api/find_points_within_area', {
    :area_id => 3983,
    :table_name => "points2df59f2cb3390905eed5"
  }

  desc <<HERE
     Find count of attributes belonging to one column

     == Parameters:
     params::
       A hash with keys row_indexes, col_name, table_name
       - row_indexes
         The row_index of points
       - col_name
         The column which is used to query the attrs with counts
         belonging to the column
       - table_name
     points table name (all points are saved to a tmp db table when importing csv)

     == Returns:
     A hash with counts of attrs and attrs of points
     {
       :count_of_attrs => {attr1 => count1, attr2 => count2, ...}
       :attrs_of_points => {index_of_point1 => attr1, index_of_point2 => attr2}
     }
HERE
  post '/api/find_filters_info', {
    :row_indexes => [12236,12237,12238,12239,12240,12323,12325,12331,12332,12357,12363,12366,12430,12431,12432,12433,12434,12435,12436,12437,12438,12439,12440,12441,12442,12443,12444,12445,12446,12447,12448,12449,12450,12451,12452,12453,12454,12455,12456,12457,12458,12459,12460,12461,12462,12463,12464,12465,12466,12467,12478,12479,12510,12535,12536,12537,12538,12541,12997,12998,12999,13079,13080,13081,13082,13083,13084,13085],
    :col_name => "project_sector",
    :table_name => "points2df59f2cb3390905eed5"
  }

  desc <<HERE
    Find all attributes and values for points
    (used for - click a point to show info)

    == Parameters:
    params::
      A hash with keys index, table_name
      - row_index
        Row_index of the point
      - table_name
          points table name (all points are saved to a tmp db table when importing csv)

    == Returns:
    A hash with attribute as key, value as value
    {
      attr1 => value1,
      attr2 => value2,
      attr3 => value3
      ...
    }
HERE
  post '/api/find_point_info', {
    :row_index => 18917,
    :table_name => "points2df59f2cb3390905eed5"
  }
end
