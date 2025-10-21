# frozen_string_literal: true

# Coordinator job that spawns individual API fetch jobs
class FetchApiDataCoordinatorJob < ApplicationJob
  queue_as :default

  # List of all APIs to fetch
  API_JOBS = [
    FetchInseeDataJob,
    FetchRneDataJob
  ].freeze

  def perform(market_application_id)
    market_application = MarketApplication.find(market_application_id)

    # Initialize all APIs as pending
    initialize_api_statuses(market_application)

    # Spawn all individual API jobs in parallel
    API_JOBS.each do |job_class|
      job_class.perform_later(market_application_id)
    end
  rescue StandardError => e
    Rails.logger.error "Error in coordinator for market application #{market_application_id}: #{e.message}"
    raise
  end

  private

  def initialize_api_statuses(market_application)
    API_JOBS.each do |job_class|
      api_name = job_class.api_name
      market_application.update_api_status(api_name, status: 'pending')
    end
  end
end
