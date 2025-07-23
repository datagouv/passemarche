# frozen_string_literal: true

module Api
  module V1
    class PublicMarketsController < BaseController
      def create
        return render json: { error: 'Editor not found' }, status: :forbidden unless current_editor

        public_market = current_editor.public_markets.build(public_market_params)

        if public_market.save
          render json: success_response(public_market), status: :created
        else
          render json: { errors: public_market.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def public_market_params
        params.require(:public_market).permit(:market_name, :lot_name, :deadline, :market_type)
      end

      def success_response(public_market)
        {
          identifier: public_market.identifier,
          configuration_url: configuration_url_for(public_market)
        }
      end

      def configuration_url_for(public_market)
        Rails.application.routes.url_helpers.configure_buyer_public_market_url(
          public_market.identifier,
          host: request.host_with_port
        )
      end
    end
  end
end
