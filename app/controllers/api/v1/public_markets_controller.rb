# frozen_string_literal: true

class Api::V1::PublicMarketsController < Api::V1::BaseController
  def create
    service = PublicMarketCreationService.new(current_editor, public_market_params).perform

    if service.success?
      render json: success_response(service.result), status: :created
    else
      render json: { errors: service.errors }, status: :unprocessable_content
    end
  end

  private

  def public_market_params
    params.expect(public_market: [:name, :lot_name, :deadline, { market_type_codes: [] }])
  end

  def success_response(public_market)
    {
      identifier: public_market.identifier,
      configuration_url: configuration_url_for(public_market)
    }
  end

  def configuration_url_for(public_market)
    Rails.application.routes.url_helpers.step_buyer_public_market_url(
      public_market.identifier,
      :setup,
      host: request.host_with_port
    )
  end
end
