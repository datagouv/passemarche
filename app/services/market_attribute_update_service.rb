# frozen_string_literal: true

class MarketAttributeUpdateService
  attr_reader :result, :errors

  def initialize(market_attribute:, params:)
    @market_attribute = market_attribute
    @params = params
    @errors = {}
  end

  def perform
    ActiveRecord::Base.transaction do
      validate_params
      update_attribute if success?
      sync_market_types if success?
      raise ActiveRecord::Rollback if failure?
    end

    @result = @market_attribute if success?
  end

  def success?
    @errors.empty?
  end

  def failure?
    !success?
  end

  private

  def add_error(key, message)
    @errors[key] = message
  end

  def validate_params
    add_error(:buyer_name, I18n.t('errors.messages.blank')) if @params[:buyer_name].blank?
    add_error(:candidate_name, I18n.t('errors.messages.blank')) if @params[:candidate_name].blank?
    validate_market_types
    validate_api_params
  end

  def validate_market_types
    ids = @params[:market_type_ids]&.compact_blank
    add_error(:market_types, I18n.t('errors.messages.blank')) if ids.blank?
  end

  def validate_api_params
    return unless api_mode?

    add_error(:api_name, I18n.t('errors.messages.blank')) if @params[:api_name].blank?
    add_error(:api_key, I18n.t('errors.messages.blank')) if @params[:api_key].blank?
  end

  def update_attribute
    @market_attribute.assign_attributes(attribute_params)
    clear_api_fields if manual_mode?

    return if @market_attribute.save

    @market_attribute.errors.each do |error|
      add_error(error.attribute, error.message)
    end
  end

  def sync_market_types
    return unless @params.key?(:market_type_ids)

    @market_attribute.market_type_ids = @params[:market_type_ids].compact_blank.map(&:to_i)
  end

  def attribute_params
    @params.except(:market_type_ids, :configuration_mode)
  end

  def api_mode?
    @params[:configuration_mode] == 'api'
  end

  def manual_mode?
    @params[:configuration_mode] == 'manual'
  end

  def clear_api_fields
    @market_attribute.api_name = nil
    @market_attribute.api_key = nil
  end
end
