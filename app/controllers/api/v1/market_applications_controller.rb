# frozen_string_literal: true

class Api::V1::MarketApplicationsController < Api::V1::BaseController
  before_action :find_public_market, only: %i[create]
  before_action :find_market_application, only: %i[attestation documents_package]
  before_action :validate_application_completed, only: %i[attestation documents_package]
  before_action :validate_attestation_available, only: %i[attestation]
  before_action :validate_documents_package_available, only: %i[documents_package]

  def create
    result = CreateMarketApplication.call(
      public_market: @public_market,
      siret: market_application_params[:siret],
      provider_user_id: market_application_params[:provider_user_id]
    )

    if result.success?
      render json: success_response(result.market_application), status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_content
    end
  end

  def attestation
    send_data @market_application.attestation.download,
      filename: "attestation_FT#{@market_application.identifier}.pdf",
      type: 'application/pdf',
      disposition: 'attachment'
  end

  def documents_package
    send_data @market_application.documents_package.download,
      filename: "documents_package_FT#{@market_application.identifier}.zip",
      type: 'application/zip',
      disposition: 'attachment'
  end

  private

  def find_public_market
    @public_market = current_editor.public_markets.find_by(identifier: params[:public_market_id])

    return if @public_market

    render json: { error: 'Public market not found' }, status: :not_found
  end

  def find_market_application
    @market_application = MarketApplication.joins(:public_market)
      .where(public_markets: { editor: current_editor })
      .find_by(identifier: params[:id])

    return if @market_application

    render json: { error: 'Market application not found' }, status: :not_found
  end

  def market_application_params
    params.fetch(:market_application, {}).permit(:siret, :provider_user_id)
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

  def validate_application_completed
    return if @market_application.completed?

    render json: { error: 'Application not completed' }, status: :unprocessable_content
  end

  def validate_attestation_available
    return if @market_application.attestation.attached?

    render json: { error: 'Attestation not available' }, status: :not_found
  end

  def validate_documents_package_available
    return if @market_application.documents_package.attached?

    render json: { error: 'Documents package not available' }, status: :not_found
  end
end
