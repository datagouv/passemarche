# frozen_string_literal: true

class ApplicationController < ActionController::Base
  private

  def after_sign_in_path_for(resource)
    case resource
    when AdminUser
      admin_root_path
    else
      super
    end
  end
end
