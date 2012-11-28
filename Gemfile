source 'https://rubygems.org'

gem 'rails', '3.2.8'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'pg'


# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

# This is an ActiveRecord connection adapter for PostGIS. It is based on the stock PostgreSQL adapter, but provides built-in support for the spatial extensions provided by PostGIS. It uses the RGeo library to represent spatial data in Ruby.
gem "activerecord-postgis-adapter", "~> 0.4.3"

# RGeo is a geospatial data library for Ruby
# homepage: http://dazuma.github.com/rgeo/
# source: https://github.com/dazuma/rgeo
# doc: http://dazuma.github.com/rgeo/rdoc/
gem "rgeo", "~> 0.3.19"

# RGeo::GeoJSON is an optional RGeo module providing GeoJSON encoding and decoding services. This module can be used to communicate with location-based web services that understand the GeoJSON forma
# homepage: http://dazuma.github.com/rgeo-geojson/
# doc: http://dazuma.github.com/rgeo-geojson/rdoc/
# source: https://github.com/dazuma/rgeo-geojson
# http://www.geojson.org/
gem "rgeo-geojson", "~> 0.2.3"

# This gem provides the leaflet.js map display library for your Rails 3 application.
# http://rubygems.org/gems/leaflet-rails
gem "leaflet-rails", "~> 0.4.5"

group :development, :test do
  gem "quiet_assets", ">= 1.0.1"
  gem "pry-rails"
  # Combine 'pry' with 'debugger'. Adds 'step', 'next', and 'continue' commands to control execution.
  # use "binding.pry" as "debugger"
  gem "pry-debugger"
end
