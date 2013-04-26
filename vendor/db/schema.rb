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

  create_table "points273ca710d88e77de73c1", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "points273ca710d88e77de73c1", ["lon_lat"], :name => "points273ca710d88e77de73c1_lon_lat", :spatial => true

  create_table "points5bb38c89a501c63410a5", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "points5bb38c89a501c63410a5", ["lon_lat"], :name => "points5bb38c89a501c63410a5_lon_lat", :spatial => true

  create_table "points5e0701cf4181ba916d8d", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "points5e0701cf4181ba916d8d", ["lon_lat"], :name => "points5e0701cf4181ba916d8d_lon_lat", :spatial => true

  create_table "points7185b87c53176183ecc9", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "points7185b87c53176183ecc9", ["lon_lat"], :name => "points7185b87c53176183ecc9_lon_lat", :spatial => true

  create_table "points7cf83ecfb32097373b7e", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "points7cf83ecfb32097373b7e", ["lon_lat"], :name => "points7cf83ecfb32097373b7e_lon_lat", :spatial => true

  create_table "points7d758764c405cd988ea5", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "points7d758764c405cd988ea5", ["lon_lat"], :name => "points7d758764c405cd988ea5_lon_lat", :spatial => true

  create_table "points837874922a79f2619be2", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "points837874922a79f2619be2", ["lon_lat"], :name => "points837874922a79f2619be2_lon_lat", :spatial => true

  create_table "points8a1a2dfd305103f67b07", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "points8a1a2dfd305103f67b07", ["lon_lat"], :name => "points8a1a2dfd305103f67b07_lon_lat", :spatial => true

  create_table "points927f7d35f7569421a982", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "points927f7d35f7569421a982", ["lon_lat"], :name => "points927f7d35f7569421a982_lon_lat", :spatial => true

  create_table "pointsa0b670e37fb2d277cf58", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "pointsa0b670e37fb2d277cf58", ["lon_lat"], :name => "pointsa0b670e37fb2d277cf58_lon_lat", :spatial => true

  create_table "pointsa7ae7f8371bdc49be207", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "pointsa7ae7f8371bdc49be207", ["lon_lat"], :name => "pointsa7ae7f8371bdc49be207_lon_lat", :spatial => true

  create_table "pointsb834b9beee38f4156ba0", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "pointsb834b9beee38f4156ba0", ["lon_lat"], :name => "pointsb834b9beee38f4156ba0_lon_lat", :spatial => true

  create_table "pointsbf27a8bbeff1feb1b263", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "pointsbf27a8bbeff1feb1b263", ["lon_lat"], :name => "pointsbf27a8bbeff1feb1b263_lon_lat", :spatial => true

  create_table "pointscf76017982296c12dbd5", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "pointscf76017982296c12dbd5", ["lon_lat"], :name => "pointscf76017982296c12dbd5_lon_lat", :spatial => true

  create_table "pointse8e73e03c1fe534c0421", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "pointse8e73e03c1fe534c0421", ["lon_lat"], :name => "pointse8e73e03c1fe534c0421_lon_lat", :spatial => true

  create_table "pointseaadd3893b09cba022c0", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "pointseaadd3893b09cba022c0", ["lon_lat"], :name => "pointseaadd3893b09cba022c0_lon_lat", :spatial => true

  create_table "pointsf557d4262a3d88866f34", :id => false, :force => true do |t|
    t.float   "lat"
    t.float   "lon"
    t.integer "row_index"
    t.spatial "lon_lat",   :limit => {:srid=>3785, :type=>"point"}
  end

  add_index "pointsf557d4262a3d88866f34", ["lon_lat"], :name => "pointsf557d4262a3d88866f34_lon_lat", :spatial => true

end
