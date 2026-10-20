# frozen_string_literal: true

class Admin::ApplicationController < ApplicationController
  include Admin::Authorization

  before_action :authenticate_admin_user!
  before_action :set_paper_trail_whodunnit

  private

  def user_for_paper_trail
    ActionView::RecordIdentifier.dom_id(current_admin_user) if current_admin_user
  end
end
