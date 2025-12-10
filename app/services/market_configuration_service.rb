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
    snapshot_mandatory_fields
    public_market
  end

  def handle_defense_market_type
    return if params.blank? || params[:add_defense_market_type] != 'true'
    return if public_market.market_type_codes.include?('defense')

    public_market.market_type_codes << 'defense'
    public_market.save!
  end

  def snapshot_mandatory_fields
    mandatory_attributes = MarketAttributeFilteringService.call(public_market).mandatory
    public_market.add_market_attributes(mandatory_attributes)
  end

  def handle_category_step
    accumulate_optional_fields
    public_market
  end

  def accumulate_optional_fields
    selected_keys = params[:selected_attribute_keys] || []
    sync_optional_fields_for_category(selected_keys)
  end

  def sync_optional_fields_for_category(selected_keys)
    available_optional_keys = available_optional_keys_for_category
    valid_selected_keys = selected_keys & available_optional_keys

    remove_deselected_optional_fields(available_optional_keys, valid_selected_keys)
    add_new_optional_fields(valid_selected_keys)
  end

  def available_optional_keys_for_category
    MarketAttributeFilteringService.call(public_market)
      .optional
      .to_a
      .select { |attr| attr.category_key == step.to_s }
      .map(&:key)
  end

  def remove_deselected_optional_fields(available_keys, selected_keys)
    keys_to_remove = available_keys - selected_keys
    return if keys_to_remove.empty?

    attributes_to_remove = public_market.market_attributes.where(key: keys_to_remove)
    public_market.market_attributes.delete(attributes_to_remove)
  end

  def add_new_optional_fields(valid_keys)
    return if valid_keys.empty?

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
