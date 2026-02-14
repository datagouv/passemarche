# frozen_string_literal: true

class MarketAttributeQueryService < ApplicationServiceObject
  def initialize(filters: {})
    super()
    @filters = filters.compact_blank
  end

  def perform
    scope = MarketAttribute.active.ordered.includes(:market_types, :subcategory)
    scope = apply_filters(scope)
    @result = scope
  end

  private

  def apply_filters(scope)
    scope = filter_by_presence(scope)
    scope = scope.where(mandatory: @filters[:mandatory]) if @filters.key?(:mandatory)
    scope
  end

  def filter_by_presence(scope)
    { category: :by_category, subcategory: :by_subcategory,
      source: :by_source, market_type_id: :by_market_type }.each do |key, scope_name|
      scope = scope.public_send(scope_name, @filters[key]) if @filters[key].present?
    end
    scope
  end
end
