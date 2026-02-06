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
    when :api_data_recovery_status, :market_information
      handle_navigation_only_step
    when :summary
      handle_summary_completion
    else
      handle_generic_step
    end
  end

  private

  attr_reader :market_application, :step, :params

  def handle_company_identification
    enqueue_api_data_fetch_if_needed
    build_result(true)
  end

  def handle_navigation_only_step
    build_result(true)
  end

  def enqueue_api_data_fetch_if_needed
    return if market_application.api_fetch_status.present?

    reset_api_statuses_to_pending
    FetchApiDataCoordinatorJob.perform_later(market_application.id)
  end

  def reset_api_statuses_to_pending
    api_names = market_application.api_names_to_fetch

    FetchApiDataCoordinatorJob::API_JOBS.each do |job_class|
      next unless api_names.include?(job_class.api_name)

      market_application.update_api_status(job_class.api_name, status: 'pending', fields_filled: 0)
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
  rescue ActiveRecord::RecordInvalid,
         ActiveRecord::RecordNotFound => e
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
