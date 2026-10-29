# frozen_string_literal: true

module Candidate
  class EnqueueApiDataFetch < ApplicationService
    def initialize(market_application:)
      @market_application = market_application
    end

    def call
      api_names = api_names_not_yet_fetched
      return if api_names.empty?

      api_names.each do |api_name|
        market_application.update_api_status(api_name, status: 'pending', fields_filled: 0)
      end

      FetchApiDataCoordinatorJob.perform_later(market_application.id, api_names)
    end

    private

    attr_reader :market_application

    def api_names_not_yet_fetched
      fetchable_api_names = FetchApiDataCoordinatorJob::API_JOBS.map(&:api_name)

      (market_application.api_names_to_fetch & fetchable_api_names) - market_application.api_fetch_status.keys
    end
  end
end
