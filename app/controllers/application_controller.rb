class ApplicationController < ActionController::Base
  protect_from_forgery


  private
    def set_tolerance
      @tolerance = params[:tolerance].to_f if params[:tolerance].present?
    end

end
