# frozen_string_literal: true

module Buyer
  class ApplicationController < ::ApplicationController
    before_action :set_paper_trail_whodunnit

    private

    def render_public_market_not_found
      render 'buyer/shared/public_market_not_found', status: :not_found
    end

    def user_for_paper_trail
      provider_user_id = @public_market&.provider_user_id
      "buyer_#{provider_user_id}" if provider_user_id.present?
    end
  end
end
