# frozen_string_literal: true

module Candidate
  class EnqueueApiDataFetch < ApplicationService
    def initialize(market_application:)
      @market_application = market_application
    end

    def call
      return if market_application.api_fetch_status.present?

      api_names = market_application.api_names_to_fetch
      FetchApiDataCoordinatorJob::API_JOBS.each do |job_class|
        next unless api_names.include?(job_class.api_name)

        market_application.update_api_status(job_class.api_name, status: 'pending', fields_filled: 0)
      end

      FetchApiDataCoordinatorJob.perform_later(market_application.id)
    end

    private

    attr_reader :market_application
  end
end
