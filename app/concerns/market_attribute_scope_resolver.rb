# frozen_string_literal: true

module MarketAttributeScopeResolver
  def scopes_for_attribute(attribute)
    type_ids = scope_lot_market_types.map(&:id)
    return [] if type_ids.empty?

    attr_type_ids = attribute.market_types.map(&:id)
    matched_type_ids = type_ids & attr_type_ids
    return [:commun] if matched_type_ids.size > 1

    scope_lot_market_types
      .select { |t| attr_type_ids.include?(t.id) }
      .map { |t| t.code.to_sym }
  end

  def scopes_for_category(category_key)
    scope_available_attributes
      .select { |a| a.category_key == category_key.to_s }
      .flat_map { |a| scopes_for_attribute(a) }
      .uniq
  end

  private

  def scope_commun_attributes(type_ids)
    scope_available_attributes.select do |attr|
      (type_ids & attr.market_types.map(&:id)).size > 1
    end
  end

  def scope_type_specific_attributes(scope, type_ids)
    target = scope_lot_market_types.find { |t| t.code == scope.to_s }
    return [] unless target

    scope_available_attributes.select do |attr|
      attr_type_ids = attr.market_types.map(&:id)
      attr_type_ids.include?(target.id) && (type_ids & attr_type_ids).size == 1
    end
  end
end
