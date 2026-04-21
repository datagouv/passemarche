# frozen_string_literal: true

class MarketApplicationStepUpdateService < ApplicationService
  attr_reader :flash_messages

  def initialize(market_application, step, params = {}, request_host: nil, request_protocol: nil)
    @market_application = market_application
    @step = step
    @params = params
    @request_host = request_host
    @request_protocol = request_protocol
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

  attr_reader :market_application, :step, :params, :request_host, :request_protocol

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
    market_application.assign_attributes(assign_existing_response_ids(params))

    if market_application.save(context: step)
      market_application.market_attribute_responses.reload
      build_result(true)
    else
      build_result(false)
    end
  end

  def handle_summary_completion
    result = CompleteMarketApplication.call(market_application:, request_host:, request_protocol:)
    result.success? ? build_result(true, redirect: :sync_status) : handle_completion_failure(result.message)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    Rails.logger.error "Error completing market application #{market_application.identifier}: #{e.message}"
    handle_completion_failure(I18n.t('candidate.market_applications.completion_error'))
  end

  def handle_completion_failure(message)
    @flash_messages[:alert] = message
    build_result(false)
  end

  def assign_existing_response_ids(original_params)
    nested = original_params[:market_attribute_responses_attributes]
    return original_params unless nested

    existing = market_application.market_attribute_responses.reload.index_by(&:market_attribute_id)

    nested.each_value do |attrs|
      next if attrs[:id].present?

      market_attr_id = attrs[:market_attribute_id].to_i
      existing_response = existing[market_attr_id]
      attrs[:id] = existing_response.id if existing_response
    end

    original_params
  end

  def build_result(success, additional_data = {})
    {
      success:,
      market_application:,
      flash_messages:
    }.merge(additional_data)
  end
end
