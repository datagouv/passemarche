# frozen_string_literal: true

class Api::V1::PublicMarketsController < Api::V1::BaseController
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
