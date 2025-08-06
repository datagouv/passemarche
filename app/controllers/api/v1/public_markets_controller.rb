# frozen_string_literal: true

class Api::V1::PublicMarketsController < Api::V1::BaseController
  def create
    public_market = PublicMarketCreationService.call(current_editor, public_market_params)
    render json: success_response(public_market), status: :created
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :forbidden
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
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
