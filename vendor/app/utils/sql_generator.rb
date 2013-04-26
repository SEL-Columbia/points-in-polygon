class SqlGenerator
  def initialize(&block)
    @select = {}
    @points_info = {}
    @areas_info = {:name => 'areas', :dump => false}
    @areas_name = "areas"
    @sub_areas = "areas"

    instance_eval(&block)
  end

  # {:id => WHICHTABLE, :count => WHICHTABLE, :index => WHICHTABLE}
  # {:id => 'areas', :count => 'points', :index => 'points'}
  def compute(*select)
    @select = select[0]
  end

  # {:name => TABLENAME, :indexes => [], }
  # {:name => 'points123457612', :indexes => , :}
  def points(*info)
    @points_info = info[0]
  end

  # {:layer_id => layer_id, :dump => true}
  def areas(*info)
    @areas_info.merge! info[0]
  end

  def to_both_query
    single_sql = to_query_str
    @areas_info[:dump] = true
    multi_sql = to_query_str
    return single_sql, multi_sql
  end

  def to_query_str
    @sub_area = get_sub_area if @areas_info[:dump]
    select_str = get_select_str
    from_str = get_from_str
    where_str = get_where_str
    group_str = "GROUP BY #{@areas_name}.id" if @select.has_key?(:count)
    [select_str, from_str, where_str, (group_str || "")] * ' '
  end
  private

  def get_sub_area
    ids = [@areas_info[:ids]].flatten
    sub_where = "WHERE (areas.id IN (#{ids * ','}))" if ids.length >= 1
    sub_where = "WHERE (areas.layer_id = #{@areas_info[:layer_id]})" if @areas_info.has_key?(:layer_id)
    @areas_name = "dumped_areas"
    "(SELECT areas.id as id, (ST_Dump(areas.multipolygon)).geom as polygon FROM areas #{sub_where}) as dumped_areas"
  end

  # {:id => 'areas', :count => 'points', :index => 'points'}
  def get_select_str
    result = []
    # maybe we want to select more than one ids?
    result << "#{@areas_name}.id" if @select.has_key?(:id)
    result << "count(#{@select[:count]})" if @select.has_key?(:count)
    result << "#{@select[:index]}.row_index" if @select.has_key?(:index)
    "SELECT ".concat (result * ',')
  end

  def get_from_str
    "FROM ".concat ([@sub_area || @areas_name, "#{@points_info[:name]} as points"] * ',')
  end

  def get_where_str
    ids = [@areas_info[:ids]].flatten if @areas_info.has_key?(:ids)
    indexes = [@points_info[:indexes].to_a] if @points_info.has_key?(:indexes)
    cond = []
    cond << "(#{@areas_name}.id IN (#{ids * ','}))" if !ids.blank? and ids.length >= 1 && !@areas_info[:dump]
    cond << "(#{@areas_name}.layer_id = #{@areas_info[:layer_id]})" if @areas_info.has_key?(:layer_id) && !@areas_info[:dump]
    cond << "(#{@areas_name}.polygon IS NOT NULL)"
    cond << "(points.row_index IN (#{indexes * ','}))" if !indexes.blank? && indexes.length >= 1
    cond << "ST_Intersects(#{@areas_name}.polygon, points.lon_lat)"
    "WHERE " << (cond * " AND ")
  end
end
