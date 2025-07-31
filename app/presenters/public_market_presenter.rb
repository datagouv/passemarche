# frozen_string_literal: true

class PublicMarketPresenter
  def initialize(public_market)
    @public_market = public_market
  end

  def required_fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(required_market_attributes)
  end

  def optional_fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(optional_market_attributes)
  end

  def all_fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(all_market_attributes)
  end

  def should_display_subcategory?(subcategories)
    subcategories.keys.size > 1
  end

  def source_types
    I18n.t('form_fields.source_types')
  end

  def field_by_key(key)
    all_market_attributes.find { |attr| attr.key == key.to_s }
  end

  private

  def required_market_attributes
    available_attributes(@public_market).required
  end

  def optional_market_attributes
    available_attributes(@public_market).additional
  end

  def all_market_attributes
    available_attributes(@public_market)
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

  def available_attributes(public_market)
    MarketAttribute.joins(:market_types)
      .where(market_types: { code: public_market.market_type_codes })
      .distinct
      .active
      .ordered
  end
end
