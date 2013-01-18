# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone

# enable to use `format.topojson { render json: @result.to_topojson }`
# Mime::Type.register "topojson", :topojson
Mime::Type.register "application/json", :topojson, %w( text/x-json application/jsonrequest )
