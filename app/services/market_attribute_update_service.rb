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
      update_attribute
      sync_market_types
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

  def update_attribute
    @market_attribute.assign_attributes(attribute_params)
    clear_api_fields if manual_mode?

    return if @market_attribute.save

    @market_attribute.errors.each do |error|
      add_error(error.attribute, error.message)
    end
  end

  def sync_market_types
    return if failure?
    return unless @params.key?(:market_type_ids)

    @market_attribute.market_type_ids = @params[:market_type_ids].compact_blank.map(&:to_i)
  end

  def attribute_params
    @params.except(:market_type_ids)
  end

  def manual_mode?
    @params[:api_name].blank?
  end

  def clear_api_fields
    @market_attribute.api_name = nil
    @market_attribute.api_key = nil
  end
end
