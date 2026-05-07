# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper_method :current_candidate

  private

  def current_candidate
    return @current_candidate if defined?(@current_candidate)

    @current_candidate = User.find_by(id: session[:user_id])
  end

  def set_no_cache_headers
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
  end

  def after_sign_in_path_for(resource)
    case resource
    when AdminUser
      admin_root_path
    else
      super
    end
  end

  def after_sign_out_path_for(_resource)
    new_admin_user_session_path
  end
end
