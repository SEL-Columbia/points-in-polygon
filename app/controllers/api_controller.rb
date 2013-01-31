class ApiController < ApplicationController

  # Query count of given points in some given areas
  #
  # == Parameters:
  # params::
  #   A hash with keys areas_ids, points, table_name
  #   - areas_ids
  #     An array including all areas you want to query
  #   - points
  #     An array including all row_indexes of points you want to query
  #   - table_name
  #     points table'name (all points info are saved to a db table when importing csv)
  #
  # == Returns:
  # A hash json with area_id as key and count as value
  # {area_id1 => count1, area_id2 => count2}
  def query_points_count_of_areas
    area_ids = params['area_ids']
    row_indexes = params['points']
    table_name = params['table_name']

    result = Query.select_points_count_of_areas area_ids, row_indexes, table_name

    render :json => JSON.generate(result)
  end

  # Query count of given points in the areas which belongs to the given layer
  #
  # == Parameters:
  # params::
  #   A hash with keys layer_id, points, table_name
  #   - layer_id
  #     Layer with the id includes some areas
  #   - points
  #     A array including indexes of points
  #   - table_name
  #     points table'name (all points info are save to a db table when importing csv)
  #
  # == Returns:
  # A hash with area_id as key and count as value
  # {area_id1 => count1, area_id2 => count2}
  def query_points_count_of_layer_areas
    layer_id = params['layer_id']
    row_indexes = params['points']
    points_table_name = params[:table_name] || nil

    result = Query.select_points_count_of_layer_areas layer_id, row_indexes, points_table_name

    render :json => JSON.generate(result)
  end

  # Find areas with counts which belong to the given area that belongs to the given layer
  # (when in the multilevel layers, click one area to show the children
  #
  # == Parameters:
  # params::
  #   A hash with keys layer_id, area_id, table_name
  #   - layer_id (Maybe it can be replaced using area's layer)
  #     The layer includes the area and can be used to judge is
  #     this level is penultimate
  #   - area_id
  #     The area is used to query its children
  #   - table_name
  #     points table'name (all points info are save to a db table when importing csv)
  #
  # == Returns:
  # A hash with children, counts, points, is_penultimate, layer_id
  # {
  #   :children =>
  #     {area_id1 => unproject_exterior_ring, ...},
  #   :counts =>
  #     {area_id1 => count1, area_id2 => count2 ...},
  #   :points =>
  #     {area_id1 => [p1, p2, ..], area_id2 => [p3, p4, ..]},
  #     (points are in area)
  #   :is_penultimate => true/false,
  #   :layer_id => the it of given layer's child
  # }
  def find_layer_children
    layer = Layer.find(params[:layer_id])
    area = Area.find(params[:area_id])
    points_table_name = params[:table_name] || nil

    if !layer.child.blank? && !points_table_name.blank?
      result = Query.select_layer_children layer, area, points_table_name
      result[:layer_id] = layer.child.id
    end

    render :json => JSON.generate(result || {})
  end

  # Find all points in the given area
  #
  # == Parameters:
  # params::
  #   A hash with keys area_id, table_name
  #   - area_id
  #     The area used to be query
  #   - table_name
  #     points table'name (all points info are save to a db table when importing csv)
  #
  # == Returns:
  # An array including the indexes of points belonging to the area
  # [p1, p2, p3 ...]
  def find_points_within_area
    area_id = params[:area_id] || nil
    points_table_name = params[:table_name] || nil

    if !area_id.blank? && !points_table_name.blank?
      points_index = Query.select_points_in_area area_id, points_table_name
    end

    render :json => JSON.generate(points_index || [])
  end

  # Find count of some attributes belonging to one column
  #   and the points which have one of the attributes
  # (must use points to find all attributes belonging to the given
  # column, because the csv info are saved with points together and
  # the client end don't know the attributes and column info)
  #
  # == Parameters:
  # params::
  #   A hash with keys row_indexes, col_name, table_name
  #   - row_indexes
  #     The row_index of points
  #   - col_name
  #     The column which is used to query the attrs with counts
  #     belonging to the column
  #   - table_name
  #     points table'name (all points info are save to a db table when importing csv)
  #
  # == Returns:
  # A hash with counts of attrs and attrs of points
  # {
  #   :count_of_attrs => {attr1 => count1, attr2 => count2, ...}
  #   :attrs_of_points => {index_of_point1 => attr1, index_of_point2 => attr2}
  # }
  def find_filters_info
    row_indexes = params[:row_indexes]
    col_name = params[:col_name]
    table_name = params[:table_name]

    count_of_attrs = Hash.new { |h, k| h[k] = 0 }
    attrs_of_points = {}
    attrs_arr = Query.query_by_str("SELECT points.attrs_json, points.row_index FROM #{table_name} as points WHERE points.row_index IN (#{row_indexes * ','})")
    attrs_arr.each do |attrs|
      # JSON parsing or regex ?
      #count_of_attrs[JSON(attrs[0].gsub(/(\w+)\s*:/, '"\1":'))[col_name]] += 1
      attr_str = attrs[0][/#{col_name}:(.*?);;;!!!/, 1]
      count_of_attrs[attr_str] += 1
      attrs_of_points[attrs[1].to_i] = attr_str
    end

    render :json => JSON.generate({:count_of_attrs => count_of_attrs, :attrs_of_points => attrs_of_points})
  end

  # Find point's info all attribues and values
  # (when click a point to show info)
  #
  # == Parameters:
  # params::
  #   A hash with keys index, table_name
  #   - row_index
  #     Row_index of the point
  #   - table_name
  #     points table'name (all points info are save to a db table when importing csv)
  #
  # == Returns:
  # A hash with attribute as key, value as value
  # {
  #   attr1 => value1,
  #   attr2 => value2,
  #   attr3 => value3
  #   ...
  # }
  def find_point_info
    index = params[:index]
    table_name = params[:table_name]
    info = Query.query_by_str("SELECT points.attrs_json FROM #{table_name} AS points WHERE points.row_index = #{index}")
    infos = info[0][0].split(';;;!!!')[1..-2].map { |attr| attr.split(':') }
    result = {}
    infos.each { |info| result[info[0]] = info[1] }

    render :json => JSON.generate(result)
  end
end
