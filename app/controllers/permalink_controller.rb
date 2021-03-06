require 'json'

class PermalinkController < ApplicationController

  # Accept the params from the layer or multi..data
  def self.generate_json(base_url, render_url, layer, tolerance, *args)
    return false unless layer
    result = args[0]
    area_points = Hash.new { |h, k| h[k] = [] }
    points_count = {}
    row_indexes = {}

    # get the area_points {:AREA_ID => POINT_IN_AREA}
    areas_unproject_rings = layer.areas.select(:unproject_exterior_ring).map(&:unproject_exterior_ring)
    layer.areas.each_with_index do |area, index|
      if tolerance
        simplied_geom = area.simplified_polygon(tolerance)
        if simplied_geom.respond_to?(:exterior_ring)
          area_points[area.id] = (Area::RGEO_FACTORY.unproject simplied_geom.exterior_ring).points.map{|point| [point.y, point.x]}
        elsif simplied_geom.respond_to?(:each)
          simplied_geom.each do |p|
            area_points[area.id] << (Area::RGEO_FACTORY.unproject p.exterior_ring).points.map{|point| [point.y, point.x]}
          end
        end
      else
        if areas_unproject_rings[index].blank?
          # generate the unproject_exterior_ring when the area has no it
          area.save_unproject_exterior_ring
          area_points[area.id] = JSON.parse(area.unproject_exterior_ring)
        else
          area_points[area.id] = JSON.parse(areas_unproject_rings[index])
        end
      end
      if result
        points_count[area.id] = area.try(:get_points_count, result)
        row_indexes[area.id] = area.try(:get_row_indexes, result)
      end
    end

    # get the view point
    view_point = area_points.values.flatten[0..1]
    data_json = {:area_points => area_points, :view_point => [view_point[0], view_point[1]], :render_url => render_url, :layer_id => layer.id}
    if result
      points_counts_array = points_count.values.select{|c| c>0}
      data_json[:points_counts_array] = points_counts_array
      data_json[:points_count] = points_count
      #data_json[:row_indexes] = row_indexes
      data_json[:points_table_name] = result[:points_table_name]
      data_json[:points_with_index] = result[:points_with_index]
      data_json[:filters] = result[:filters]
    end
    #if rows
    #  data_json[:rows] = rows
    #end

    # write the json data to a json file as cache
    #data_json = data_json.to_json   # slow
    data_json = JSON.generate(data_json)
    file_name = "#{SecureRandom.hex(18)}.json"
    file_path = "public/permalink/#{file_name}"
    FileUtils.mkdir_p(File.dirname(file_path))
    File.open(file_path, 'w') { |f| f.write(data_json) }

    {:url => "#{base_url}/permalink/#{file_name}"[0...-5], :data_json => data_json, :file_path => file_path}
  end

  def show
    file_path = "public/permalink/#{params[:key]}.json"
    @data_json = File.read(file_path)

    render :template => @data_json.match(/\"render_url\":\"(.*?)\"/)[1]
  end
end
