class ApplicationController < ActionController::Base
  protect_from_forgery

  #before_filter :set_format

  #def set_format
  #  request.format = 'json'
  #end


  private
    def set_tolerance
      @tolerance = params[:tolerance].to_f if params[:tolerance].present?
    end

end
