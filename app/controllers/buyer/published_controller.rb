# frozen_string_literal: true

module Buyer
  class PublishedController < Buyer::ApplicationController
    prepend_before_action :find_public_market

    def show; end

    private

    def find_public_market
      @public_market = PublicMarket.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render_public_market_not_found
    end
  end
end
