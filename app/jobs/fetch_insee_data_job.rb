# frozen_string_literal: true

# Background job to fetch data from INSEE API
class FetchInseeDataJob < ApplicationJob
  queue_as :default

  def self.api_name
    'Insee'
  end

  def perform(market_application_id)
    market_application = MarketApplication.find(market_application_id)

    return if market_application.siret.blank?

    fetch_and_process_data(market_application)
  rescue StandardError => e
    handle_error(market_application, market_application_id, e)
  end

  private

  def fetch_and_process_data(market_application)
    log_start(market_application)
    update_to_processing(market_application)

    result = Insee.call(
      params: { siret: market_application.siret },
      market_application:
    )

    handle_result(market_application, result)
    log_completion(market_application)
  end

  def log_start(market_application)
    Rails.logger.info "Starting INSEE fetch for MA #{market_application.id}, current status: #{market_application.api_fetch_status}"
  end

  def update_to_processing(market_application)
    market_application.update_api_status(self.class.api_name, status: 'processing')
    Rails.logger.info "Set INSEE to processing, status now: #{market_application.reload.api_fetch_status}"
  end

  def log_completion(market_application)
    Rails.logger.info "Completed INSEE fetch for MA #{market_application.id}, final status: #{market_application.reload.api_fetch_status}"
  end

  def handle_result(market_application, result)
    if result.success?
      fields_count = count_filled_fields(market_application)
      Rails.logger.info "INSEE success: updating status to completed with #{fields_count} fields"
      market_application.update_api_status(self.class.api_name, status: 'completed', fields_filled: fields_count)
      Rails.logger.info "After update_api_status, persisted status: #{market_application.reload.api_fetch_status}"
    else
      Rails.logger.warn 'INSEE failed: result was not successful'
      handle_failure(market_application)
    end
  end

  def handle_failure(market_application)
    mark_api_attributes_as_manual_after_failure(market_application)
    market_application.update_api_status(self.class.api_name, status: 'failed', fields_filled: 0)
  end

  def handle_error(market_application, market_application_id, error)
    Rails.logger.error "Error fetching INSEE data for #{market_application_id}: #{error.message}"
    market_application&.update_api_status(self.class.api_name, status: 'failed', fields_filled: 0)
    raise
  end

  def count_filled_fields(market_application)
    market_application.market_attribute_responses
      .joins(:market_attribute)
      .where(market_attributes: { api_name: self.class.api_name })
      .where(source: :auto)
      .count
  end

  def mark_api_attributes_as_manual_after_failure(market_application)
    api_attributes = market_application.public_market.market_attributes
      .where(api_name: self.class.api_name)

    api_attributes.each do |attribute|
      response = market_application.market_attribute_responses
        .find_or_initialize_by(market_attribute: attribute)

      next if response.manual_after_api_failure?

      response.source = :manual_after_api_failure
      response.save! if response.persisted? || response.changed?
    end
  end
end
