# frozen_string_literal: true

class MarketApplicationPresenter
  def initialize(market_application)
    @market_application = market_application
  end

  def fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(all_market_attributes)
  end

  def subcategories_for_category(category_key)
    return [] if category_key.blank?

    all_market_attributes
      .where(category_key:)
      .reorder(:subcategory_key)
      .distinct
      .pluck(:subcategory_key)
      .compact
  end

  def field_by_key(key)
    MarketAttribute.find_by(key: key.to_s)
  end

  def market_attributes_for_subcategory(category_key, subcategory_key)
    return [] if category_key.blank? || subcategory_key.blank?

    all_market_attributes
      .where(category_key:, subcategory_key:)
      .order(:id)
  end

  def market_attribute_response_for(market_attribute)
    @market_application.market_attribute_responses.find { |response| response.market_attribute_id == market_attribute.id } ||
      @market_application.market_attribute_responses.build(
        market_attribute:,
        type: MarketAttributeResponse.type_from_input_type(market_attribute.input_type)
      )
  end

  def responses_for_subcategory(category_key, subcategory_key)
    return [] if category_key.blank? || subcategory_key.blank?

    market_attributes = market_attributes_for_subcategory(category_key, subcategory_key)
    market_attributes.map { |attr| market_attribute_response_for(attr) }
  end

  def responses_for_category(category_key)
    return [] if category_key.blank?

    all_market_attributes
      .where(category_key:)
      .order(:id)
      .map { |attr| market_attribute_response_for(attr) }
  end

  def responses_grouped_by_subcategory(category_key)
    responses_for_category(category_key).group_by { |r| r.market_attribute.subcategory_key }
  end

  def should_display_subcategory?(subcategories)
    subcategories.keys.size > 1
  end

  private

  def all_market_attributes
    @market_application.public_market.market_attributes.active.ordered
  end

  def organize_fields_by_category_and_subcategory(market_attributes)
    category_keys = @market_application.public_market.market_attributes
      .order(:id)
      .pluck(:category_key)
      .compact
      .uniq

    category_keys.each_with_object({}) do |category_key, result|
      category_attrs = market_attributes.select { |attr| attr.category_key == category_key }
      result[category_key] = group_by_subcategory(category_attrs) if category_attrs.any?
    end
  end

  def group_by_subcategory(market_attributes)
    market_attributes
      .group_by(&:subcategory_key)
      .transform_values { |subcategory_attrs| subcategory_attrs.map(&:key) }
  end
end
