# frozen_string_literal: true

class MarketConfigurationService < ApplicationService
  def initialize(public_market, step, params = {})
    @public_market = public_market
    @step = step
    @params = params
  end

  def call
    case step
    when :setup
      handle_setup_step
    when :summary
      complete_market
    else
      handle_category_step
    end
  end

  private

  attr_reader :public_market, :step, :params

  def handle_setup_step
    handle_defense_market_type
    snapshot_required_fields
    public_market
  end

  def handle_defense_market_type
    return if params.blank? || params[:add_defense_market_type] != 'true'
    return if public_market.market_type_codes.include?('defense')

    public_market.market_type_codes << 'defense'
    public_market.save!
  end

  def snapshot_required_fields
    required_attributes = MarketAttributeFilteringService.call(public_market).required
    public_market.add_market_attributes(required_attributes)
  end

  def handle_category_step
    accumulate_optional_fields
    public_market
  end

  def accumulate_optional_fields
    selected_keys = params[:selected_attribute_keys] || []
    return if selected_keys.empty?

    valid_keys = filter_valid_optional_keys(selected_keys)
    return if valid_keys.empty?

    add_new_attributes(valid_keys)
  end

  def filter_valid_optional_keys(selected_keys)
    available_keys = MarketAttributeFilteringService.call(public_market)
      .additional
      .to_a
      .select { |attr| attr.category_key == step.to_s }
      .map(&:key)

    selected_keys & available_keys
  end

  def add_new_attributes(valid_keys)
    new_attributes = MarketAttribute.where(key: valid_keys).reject do |attr|
      public_market.market_attributes.include?(attr)
    end
    public_market.market_attributes << new_attributes
  end

  def complete_market
    public_market.complete!

    PublicMarketWebhookJob.perform_later(public_market.id)

    public_market
  end
end
