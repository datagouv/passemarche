# frozen_string_literal: true

module Buyer
  class PublicMarketsController < ApplicationController
    before_action :find_public_market, only: [:configure]

    def configure
      # Placeholder for configuration page
      # Will be designed and implemented in next step
    end

    private

    def find_public_market
      @public_market = PublicMarket.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: 'Le marché recherché n\'a pas été trouvé', status: :not_found
    end
  end
end
