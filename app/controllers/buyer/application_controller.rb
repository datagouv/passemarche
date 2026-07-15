# frozen_string_literal: true

module Buyer
  class ApplicationController < ::ApplicationController
    before_action :set_paper_trail_whodunnit

    private

    def user_for_paper_trail
      @public_market&.provider_user_id
    end
  end
end
