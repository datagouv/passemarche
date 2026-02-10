# frozen_string_literal: true

class Admin::ApplicationController < ApplicationController
  include Admin::Authorization

  before_action :authenticate_admin_user!
end
