# frozen_string_literal: true

# Coordinator job that spawns individual API fetch jobs
class FetchApiDataCoordinatorJob < ApplicationJob
  queue_as :default

  # List of all APIs to fetch
  API_JOBS = [
    FetchInseeDataJob,
    FetchRneDataJob,
    FetchDgfipDataJob,
    FetchQualibatDataJob
  ].freeze

  def perform(market_application_id)
    # Spawn all individual API jobs in parallel
    # Note: API statuses are already initialized as 'pending' by the service before this job runs
    API_JOBS.each do |job_class|
      job_class.perform_later(market_application_id)
    end
  rescue StandardError => e
    Rails.logger.error "Error in coordinator for market application #{market_application_id}: #{e.message}"
    raise
  end
end
