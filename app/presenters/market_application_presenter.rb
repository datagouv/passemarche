# frozen_string_literal: true

class MarketApplicationPresenter
  def initialize(market_application)
    @market_application = market_application
  end

  def fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(all_market_attributes)
  end

  def field_by_key(key)
    MarketAttribute.find_by(key: key.to_s)
  end

  def should_display_subcategory?(subcategories)
    subcategories.keys.size > 1
  end

  private

  def all_market_attributes
    @market_application.public_market.market_attributes.active.ordered
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
end
