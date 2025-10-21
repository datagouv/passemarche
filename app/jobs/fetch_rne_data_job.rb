# frozen_string_literal: true

# Background job to fetch data from RNE API
class FetchRneDataJob < ApplicationJob
  queue_as :default

  def self.api_name
    'rne'
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
    market_application.update_api_status(self.class.api_name, status: 'processing')

    result = Rne.call(
      params: { siret: market_application.siret },
      market_application:
    )

    handle_result(market_application, result)
  end

  def handle_result(market_application, result)
    if result.success?
      fields_count = count_filled_fields(market_application)
      market_application.update_api_status(self.class.api_name, status: 'completed', fields_filled: fields_count)
    else
      handle_failure(market_application)
    end
  end

  def handle_failure(market_application)
    mark_api_attributes_as_manual_after_failure(market_application)
    market_application.update_api_status(self.class.api_name, status: 'failed', fields_filled: 0)
  end

  def handle_error(market_application, market_application_id, error)
    Rails.logger.error "Error fetching RNE data for #{market_application_id}: #{error.message}"
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
