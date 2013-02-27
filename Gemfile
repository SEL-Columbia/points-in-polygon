source 'https://rubygems.org'

gem 'rails', '3.2.11'
gem 'pg'

gem 'api_taster' #Gem for autogenerating API docs

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'therubyracer', :platforms => :ruby # for deploy
  gem 'uglifier', '>= 1.0.3'
  gem 'ejs', "~> 1.1.1"
end

gem 'jquery-rails'
gem "activerecord-postgis-adapter", "~> 0.4.3"
gem "json", "~> 1.7.6"
gem 'rabl'
gem 'rubyzip', "~> 0.9.9"

gem "rgeo", "~> 0.3.19"
gem 'ffi-geos'
gem "rgeo-geojson", "~> 0.2.3"
gem 'rgeo-shapefile', "~> 0.2.3"
#gem "leaflet-rails", "~> 0.4.5"


group :development, :test do
  gem "thin", "~> 1.5.0"
  gem "rack-mini-profiler", "~> 0.1.23"
  gem "quiet_assets", ">= 1.0.1"
  gem "pry-rails"
  gem "pry-debugger"

  gem 'rspec-rails'
  gem 'spork-rails'
  gem 'factory_girl_rails'
  gem 'shoulda'
  gem 'database_cleaner'
  gem 'multi_json'
end

group :development do
  gem 'rvm-capistrano', require: false # required by newer version of rvm
  gem 'capistrano'
  gem 'capistrano-ext'
end
