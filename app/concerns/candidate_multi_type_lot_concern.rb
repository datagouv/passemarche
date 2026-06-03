# frozen_string_literal: true

module CandidateMultiTypeLotConcern
  def lots_by_effective_type
    @lots_by_effective_type ||= selected_lots.group_by(&:effective_market_type)
  end

  def selected_lot_types
    @selected_lot_types ||= @market_application.selected_lot_types
  end

  delegate :multi_type_selected_lots?, to: :@market_application

  def fields_count_for_scope(scope)
    attributes_for_scope(scope).size
  end

  def filled_fields_count_for_scope(scope)
    attributes_for_scope(scope).count do |attr|
      response = responses_by_attribute_id[attr.id]
      response_has_data?(response)
    end
  end

  def attributes_for_scope(scope)
    type_ids = selected_lot_types.map(&:id)
    return [] if type_ids.empty?

    scope == :commun ? common_scope_attributes(type_ids) : type_scope_attributes(scope, type_ids)
  end

  def first_step_for_scope(scope)
    attrs = attributes_for_scope(scope)
    return :api_data_recovery_status if attrs.empty?

    attrs.filter_map(&:subcategory_key).first&.to_sym || :api_data_recovery_status
  end

  def lots_by_type_sorted
    @lots_by_type_sorted ||= public_market.lots.ordered
      .includes(:market_type, :platform_market_type)
      .group_by(&:effective_market_type)
  end

  private

  def common_scope_attributes(type_ids)
    all_market_attributes.select do |attr|
      (type_ids & attr.market_types.map(&:id)).size > 1
    end
  end

  def type_scope_attributes(scope, type_ids)
    target = selected_lot_types.find { |t| t.code == scope.to_s }
    return [] unless target

    all_market_attributes.select do |attr|
      attr_type_ids = attr.market_types.map(&:id)
      attr_type_ids.include?(target.id) && (type_ids & attr_type_ids).size == 1
    end
  end
end
