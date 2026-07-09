# frozen_string_literal: true

module MultiTypeLotConcern
  include MarketAttributeScopeResolver

  def lot_market_types
    @lot_market_types ||= lots_for_config.filter_map(&:effective_market_type).uniq
  end

  alias scope_lot_market_types lot_market_types

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

    scope == :commun ? scope_commun_attributes(type_ids) : scope_type_specific_attributes(scope, type_ids)
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

  def scope_available_attributes
    available_attributes_array
  end
end
