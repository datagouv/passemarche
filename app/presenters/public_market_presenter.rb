# frozen_string_literal: true

class PublicMarketPresenter
  include SidemenuHelper

  def initialize(public_market)
    @public_market = public_market
  end

  def available_required_fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(available_required_market_attributes)
  end

  def available_optional_fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(available_optional_market_attributes)
  end

  def all_fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(all_market_attributes)
  end

  def required_fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(all_market_attributes.required)
  end

  def optional_fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(all_market_attributes.additional)
  end

  def source_types
    I18n.t('form_fields.source_types')
  end

  def field_by_key(key)
    MarketAttribute.find_by(key: key.to_s)
  end

  def available_required_market_attributes
    available_attributes.required
  end

  private

  def available_optional_market_attributes
    available_attributes.additional
  end

  def all_market_attributes
    @public_market.market_attributes.active.ordered
  end

  def organize_fields_by_category_and_subcategory(market_attributes)
    market_attributes
      .group_by(&:category_key)
      .transform_values { |category_attrs| group_by_subcategory(category_attrs) }
  end

  def group_by_subcategory(market_attributes)
    market_attributes
      .group_by(&:subcategory_key)
      .transform_values { |subcategory_attrs| subcategory_attrs.map(&:key) }
  end

  def available_attributes
    @available_attributes ||= MarketAttributeFilteringService.call(@public_market)
  end
end
