# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130105142749) do

  create_table "areas", :force => true do |t|
    t.integer  "layer_id"
    t.datetime "created_at",                                                          :null => false
    t.datetime "updated_at",                                                          :null => false
    t.spatial  "polygon",                 :limit => {:srid=>3785, :type=>"polygon"}
    t.text     "unproject_exterior_ring"
    t.spatial  "multipolygon",            :limit => {:srid=>3785, :type=>"geometry"}
    t.integer  "level_id"
    t.integer  "parent_id"
  end

  add_index "areas", ["multipolygon"], :name => "index_areas_on_multipolygon", :spatial => true
  add_index "areas", ["polygon"], :name => "index_areas_on_polygon", :spatial => true

  create_table "layers", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "parent_id"
  end

  create_table "points", :force => true do |t|
    t.string  "name"
    t.decimal "lat"
    t.decimal "lon"
    t.spatial "lat_lon",   :limit => {:srid=>3785, :type=>"point"}
    t.integer "row_index"
  end

  add_index "points", ["lat_lon"], :name => "index_points_on_lat_lon", :spatial => true

  create_table "points927f7d35f7569421a982", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "points927f7d35f7569421a982", ["lon_lat"], :name => "points927f7d35f7569421a982_lon_lat", :spatial => true

  create_table "pointsbf27a8bbeff1feb1b263", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "pointsbf27a8bbeff1feb1b263", ["lon_lat"], :name => "pointsbf27a8bbeff1feb1b263_lon_lat", :spatial => true

  create_table "pointseaadd3893b09cba022c0", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "pointseaadd3893b09cba022c0", ["lon_lat"], :name => "pointseaadd3893b09cba022c0_lon_lat", :spatial => true

end
