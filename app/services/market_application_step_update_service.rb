# frozen_string_literal: true

class MarketApplicationStepUpdateService < ApplicationService
  attr_reader :flash_messages

  def initialize(market_application, step, params = {}, draft: false)
    @market_application = market_application
    @step = step
    @params = params
    @draft = draft
    @flash_messages = {}
  end

  def call
    return build_result(true) if draft && step == :summary

    case step
    when :api_data_recovery_status
      handle_navigation_only_step
    when :market_information
      handle_market_information_step
    when :summary
      handle_summary_completion
    else
      handle_generic_step
    end
  end

  private

  attr_reader :market_application, :step, :params, :draft

  def handle_navigation_only_step
    build_result(true)
  end

  def handle_market_information_step
    market_application.with_grouping_edit_lock { true }
    build_result(true)
  end

  def handle_generic_step
    market_application.assign_attributes(assign_existing_response_ids(params))

    if save_step
      market_application.market_attribute_responses.reload
      build_result(true)
    else
      handle_step_failure
    end
  end

  def save_step
    market_application.with_grouping_edit_lock do
      market_application.save(context: step) || raise(ActiveRecord::Rollback)
    end
  end

  def handle_step_failure
    @flash_messages[:alert] = I18n.t('candidate.market_applications.draft_failed') if draft
    build_result(false)
  end

  def handle_summary_completion
    return handle_grouping_member_completion if market_application.grouping_member

    result = CompleteMarketApplication.call(market_application:)
    result.success? ? build_result(true, completed: true) : handle_completion_failure(result.message)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    Rails.logger.error "Error completing market application #{market_application.identifier}: #{e.message}"
    handle_completion_failure(I18n.t('candidate.market_applications.completion_error'))
  end

  def handle_grouping_member_completion
    result = Candidate::CompleteGroupingMember.call(market_application:)
    result.success? ? build_result(true, completed: true) : handle_completion_failure(result.message)
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
    result = { success:, market_application:, flash_messages: }
    result[:draft] = true if draft
    result.merge(additional_data)
  end
end
