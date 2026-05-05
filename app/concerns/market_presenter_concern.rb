# frozen_string_literal: true

module MarketPresenterConcern
  def group_by_subcategory(market_attributes)
    market_attributes
      .group_by(&:subcategory_key)
      .transform_values { |subcategory_attrs| subcategory_attrs.map(&:key) }
  end

  def field_by_key(key)
    MarketAttribute.find_by(key: key.to_s)
  end
end
