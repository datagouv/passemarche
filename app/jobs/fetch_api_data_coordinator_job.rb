# frozen_string_literal: true

class FetchApiDataCoordinatorJob < ApplicationJob
  queue_as :default

  API_JOBS = [
    FetchInseeDataJob,
    FetchRneDataJob,
    FetchDgfipDataJob,
    FetchQualibatDataJob,
    FetchProbtpDataJob
  ].freeze

  def perform(market_application_id)
    market_application = MarketApplication.find(market_application_id)

    spawn_relevant_api_jobs(market_application, market_application_id)
  rescue StandardError => e
    log_coordinator_error(market_application_id, e)
    raise
  end

  private

  def spawn_relevant_api_jobs(market_application, market_application_id)
    api_names = market_application.api_names_to_fetch

    API_JOBS.each do |job_class|
      job_class.perform_later(market_application_id) if api_names.include?(job_class.api_name)
    end
  end

  def log_coordinator_error(market_application_id, error)
    Rails.logger.error "Error in coordinator for market application #{market_application_id}: #{error.message}"
  end
end
