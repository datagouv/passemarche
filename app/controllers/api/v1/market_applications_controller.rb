# frozen_string_literal: true

class Api::V1::MarketApplicationsController < Api::V1::BaseController
  before_action :find_public_market

  def create
    return unless @public_market

    service = MarketApplicationCreationService.new(
      public_market: @public_market,
      siret: market_application_params[:siret]
    ).perform

    if service.success?
      render json: success_response(service.result), status: :created
    else
      render json: { errors: service.errors }, status: :unprocessable_content
    end
  end

  private

  def find_public_market
    @public_market = current_editor.public_markets.find_by(identifier: params[:public_market_id])

    return if @public_market

    render json: { error: 'Public market not found' }, status: :not_found
  end

  def market_application_params
    params.fetch(:market_application, {}).permit(:siret)
  end

  def success_response(market_application)
    {
      identifier: market_application.identifier,
      application_url: application_url_for(market_application)
    }
  end

  def application_url_for(market_application)
    Rails.application.routes.url_helpers.step_candidate_market_application_url(
      market_application.identifier,
      :company_identification,
      host: request.host_with_port
    )
  end
end
