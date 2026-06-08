# frozen_string_literal: true

module MultiTypeLotConcern
  def lot_market_types
    @lot_market_types ||= lots_for_config.filter_map(&:effective_market_type).uniq
  end

  def scopes
    return [] unless multi_type_lots?

    [:commun] + lot_market_types.map { |t| t.code.to_sym }
  end

  def lot_count_for_scope(scope)
    return lots_for_config.size if scope == :commun

    lots_for_config.count { |lot| lot.effective_market_type&.code == scope.to_s }
  end

  def attributes_for_scope(scope)
    type_ids = lot_market_types.map(&:id)
    return [] if type_ids.empty?

    scope == :commun ? common_attributes(type_ids) : type_specific_attributes(scope, type_ids)
  end

  def scopes_for_attribute(attribute)
    type_ids = lot_market_types.map(&:id)
    return [] if type_ids.empty?

    attr_type_ids = attribute.market_types.map(&:id)
    matched_type_ids = type_ids & attr_type_ids
    return [:commun] if matched_type_ids.size > 1

    lot_market_types
      .select { |t| attr_type_ids.include?(t.id) }
      .map { |t| t.code.to_sym }
  end

  def lots_by_effective_type
    lots_for_config.group_by(&:effective_market_type)
  end

  def lot_effective_type_label(lot)
    type = lot.effective_market_type
    return nil unless type

    I18n.t("market_types.#{type.code}", default: type.code.humanize)
  end

  private

  def common_attributes(type_ids)
    available_attributes_array.select do |attr|
      (type_ids & attr.market_types.map(&:id)).size > 1
    end
  end

  def type_specific_attributes(scope, type_ids)
    target = lot_market_types.find { |t| t.code == scope.to_s }
    return [] unless target

    available_attributes_array.select do |attr|
      attr_type_ids = attr.market_types.map(&:id)
      attr_type_ids.include?(target.id) && (type_ids & attr_type_ids).size == 1
    end
  end
end
