# frozen_string_literal: true

class ApplicationController < ActionController::Base
  private

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
end
