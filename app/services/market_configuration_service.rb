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
      handle_defense_market_type
    when :required_fields
      snapshot_required_fields
    when :additional_fields
      snapshot_additional_fields
    when :summary
      complete_market
    else
      raise ArgumentError, "Unknown step: #{step}"
    end
  end

  private

  attr_reader :public_market, :step, :params

  def handle_defense_market_type
    return public_market if params.blank? || params[:add_defense_market_type] != 'true'
    return public_market if public_market.market_type_codes.include?('defense')

    public_market.market_type_codes << 'defense'
    public_market.save!
    public_market
  end

  def snapshot_required_fields
    presenter = PublicMarketPresenter.new(public_market)
    public_market.market_attributes = presenter.available_required_market_attributes
    public_market.save!

    { public_market: public_market, next_step: :additional_fields }
  end

  def snapshot_additional_fields
    selected_attribute_keys = params[:selected_attribute_keys] || []
    selected_optional_attributes = MarketAttribute.where(key: selected_attribute_keys)
    existing_required_attributes = public_market.market_attributes.required
    all_attributes = (existing_required_attributes + selected_optional_attributes).uniq

    public_market.market_attributes = all_attributes
    public_market.save!

    { public_market: public_market, next_step: :summary }
  end

  def complete_market
    public_market.complete!
    public_market
  end
end
