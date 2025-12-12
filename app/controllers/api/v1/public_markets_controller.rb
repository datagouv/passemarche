# frozen_string_literal: true

class Api::V1::PublicMarketsController < Api::V1::BaseController
  before_action :validate_defense_market_permission, only: [:create]

  def create
    service = PublicMarketCreationService.new(current_editor, public_market_params).perform

    if service.success?
      render json: success_response(service.result), status: :created
    else
      render json: { errors: service.errors }, status: :unprocessable_content
    end
  end

  private

  def validate_defense_market_permission
    return unless public_market_params[:market_type_codes]&.include?('defense')
    return if current_editor.can_create_defense_markets?

    render json: {
      errors: {
        market_type_codes: [I18n.t('api.errors.defense_market_not_allowed')]
      }
    }, status: :forbidden
  end

  def public_market_params
    params.expect(public_market: [:name, :lot_name, :deadline, :siret, { market_type_codes: [] }])
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
