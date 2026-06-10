# frozen_string_literal: true

class Api::V1::PublicMarketsController < Api::V1::BaseController
  before_action :validate_defense_market_permission, only: [:create]
  before_action :find_public_market, only: [:update]

  def create
    result = CreatePublicMarket.call(editor: current_editor, params: create_params)

    if result.success?
      render json: success_response(result.public_market), status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_content
    end
  end

  def update
    if @public_market.update(update_params)
      render json: { identifier: @public_market.identifier, deadline: @public_market.deadline.utc.iso8601 }
    else
      render json: { errors: @public_market.errors.messages }, status: :unprocessable_content
    end
  end

  private

  def find_public_market
    @public_market = current_editor.public_markets.find_by!(identifier: params[:identifier])
  end

  def validate_defense_market_permission
    return unless create_params[:market_type_codes]&.include?('defense')
    return if current_editor.can_create_defense_markets?

    render json: {
      errors: {
        market_type_codes: [I18n.t('api.errors.defense_market_not_allowed')]
      }
    }, status: :forbidden
  end

  def create_params
    params.expect(public_market: [:name, :deadline, :siret, :provider_user_id, :lot_limit,
                                  { market_type_codes: [], lots: [%i[name cpv_code]] }])
  end

  def update_params
    params.expect(public_market: [:deadline])
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
