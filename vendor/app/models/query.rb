class Query < ActiveRecord::Base
  ## TODO: maybe there is a better way to integrate below two
  ## method to one(using one geometry field to save polygon or multipolygon?)

  ## WARNING: In some methods which needs to concat the points or areas
  ## the sql may be too long

  # Given [areaid1, areaid2, ...], [index1, inedex2], table_name of the tmp points
  def self.select_points_count_of_areas(area_ids, row_indexes, table_name)
    counts = {}
    if row_indexes.blank?
      return {:counts => []}
    end

    single_sql, multi_sql = * SqlGenerator.new do
      compute :id => 'areas', :count => 'points'
      points :name => table_name, :indexes => row_indexes
      areas :ids => area_ids
    end.to_both_query
    result = self.connection.execute(single_sql).values
    result.concat self.connection.execute(multi_sql).values

    result.each { |i| counts[i[0]] = i[1].to_i }
    {:counts => counts}
  end

  # Given layer_id, row_index field in points table of points, tmp table name
  def self.select_points_count_of_layer_areas(layer_id, row_indexes, table_name)

    counts = {}
    if row_indexes.blank?
      return {:counts => []}
    end
    single_sql, multi_sql = SqlGenerator.new do
      compute :id => 'areas', :count => 'points'
      points :name => table_name, :indexes => row_indexes
      areas :layer_id => layer_id
    end.to_both_query
    result = self.connection.execute(single_sql).values
    result.concat self.connection.execute(multi_sql).values

    result.each { |i| counts[i[0]] = i[1].to_i }
    {:counts => counts}
  end

  # Given layer, area, table_name
  def self.select_layer_children layer, area, table_name

    children = {}
    counts = Hash.new(0)
    points = Hash.new {|h, k| h[k] = [] }

    area_ids = layer.child.areas.select(:id).where(:parent_id => area.level_id).map(&:id)

    single_sql, multi_sql = * SqlGenerator.new do
      compute :id => 'areas', :index => 'points'
      points(:name => table_name)
      areas :ids => area_ids
    end.to_both_query
    result = self.connection.execute(single_sql).values
    result.concat self.connection.execute(multi_sql).values

    is_penultimate = layer.child.child.blank?
    result.each do |i|
      counts[i[0]] += 1
      points[i[0]] << i[1].to_i #if is_penultimate
    end

    Area.where(:id => area_ids).select("id, unproject_exterior_ring").map { |r| children[r.id] = JSON.parse(r.unproject_exterior_ring) }

    {:children => children, :counts => counts, :points => points, :is_penultimate => is_penultimate}
  end

  def self.select_points_in_area(area_id, table_name)

    single_sql, multi_sql = * SqlGenerator.new do
      compute :index => 'points'
      points :name => table_name
      areas :ids => area_id
    end.to_both_query
    points_index = self.connection.execute(single_sql).values

    if points_index.length <= 0
      points_index = self.connection.execute(multi_sql).values
    end
    points_index.map{|p| p[0].to_i}
  end

  def self.query_by_str(str)
    self.connection.execute(str).values
  end
end
