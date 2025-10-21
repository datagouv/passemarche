# frozen_string_literal: true

class MarketApplicationStepUpdateService < ApplicationService
  attr_reader :flash_messages

  def initialize(market_application, step, params = {})
    @market_application = market_application
    @step = step
    @params = params
    @flash_messages = {}
  end

  def call
    case step
    when :company_identification
      handle_company_identification
    when :api_data_recovery_status
      handle_api_data_recovery_status
    when :summary
      handle_summary_completion
    else
      handle_generic_step
    end
  end

  private

  attr_reader :market_application, :step, :params

  def handle_company_identification
    market_application.assign_attributes(params)

    return build_result(false) unless market_application.save(context: step)

    # Enqueue coordinator job to fetch API data
    FetchApiDataCoordinatorJob.perform_later(market_application.id)

    build_result(true)
  end

  def handle_api_data_recovery_status
    # Simple passthrough - this step is just for displaying sync status
    build_result(true)
  end

  def populate_api_data
    populate_insee_data
    populate_rne_data
  end

  def populate_insee_data
    return if market_application.siret.blank?

    result = Insee.call(
      params: { siret: market_application.siret },
      market_application:
    )

    return if result.success?

    mark_api_attributes_as_manual_after_failure('Insee')
    @flash_messages[:alert] = I18n.t('candidate.market_applications.insee_api_error', error: result.error)
  end

  def populate_rne_data
    return if market_application.siret.blank?

    result = Rne.call(
      params: { siret: market_application.siret },
      market_application:
    )

    return if result.success?

    mark_api_attributes_as_manual_after_failure('rne')
    @flash_messages[:alert] = I18n.t('candidate.market_applications.rne_api_error', error: result.error)
  end

  def mark_api_attributes_as_manual_after_failure(api_name)
    api_attributes = market_application.public_market.market_attributes
      .where(api_name:)

    api_attributes.each do |attribute|
      response = market_application.market_attribute_responses
        .find_or_initialize_by(market_attribute: attribute)

      next if response.manual_after_api_failure?

      response.source = :manual_after_api_failure
      response.save! if response.persisted? || response.changed?
    end
  end

  def handle_generic_step
    market_application.assign_attributes(params)

    if market_application.save(context: step)
      market_application.market_attribute_responses.reload
      build_result(true)
    else
      build_result(false)
    end
  end

  def handle_summary_completion
    result = CompleteMarketApplication.call(market_application:)

    if result.success?
      build_result(true, redirect: :sync_status)
    else
      @flash_messages[:alert] = result.message
      build_result(false)
    end
  rescue StandardError => e
    Rails.logger.error "Error completing market application #{market_application.identifier}: #{e.message}"
    @flash_messages[:alert] = I18n.t('candidate.market_applications.completion_error')
    build_result(false)
  end

  def build_result(success, additional_data = {})
    {
      success:,
      market_application:,
      flash_messages:
    }.merge(additional_data)
  end
end
