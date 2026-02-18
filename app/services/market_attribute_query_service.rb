# frozen_string_literal: true

class MarketAttributeQueryService < ApplicationService
  def initialize(filters: {})
    @filters = filters.compact_blank
  end

  def call
    scope = MarketAttribute.active.ordered.includes(:market_types, subcategory: :category)
    scope = apply_filters(scope)
    scope = apply_search(scope) if @filters[:query].present?
    scope
  end

  private

  def apply_filters(scope)
    scope = scope.by_category(@filters[:category]) if @filters[:category].present?
    scope = scope.by_source(@filters[:source]) if @filters[:source].present?
    scope = scope.by_market_type(@filters[:market_type_id]) if @filters[:market_type_id].present?
    scope
  end

  def apply_search(scope)
    query = "%#{MarketAttribute.sanitize_sql_like(@filters[:query])}%"
    scope.joins(subcategory: :category)
      .where(
        'categories.buyer_label ILIKE :q OR subcategories.buyer_label ILIKE :q ' \
        'OR market_attributes.key ILIKE :q OR market_attributes.buyer_name ILIKE :q',
        q: query
      )
  end
end
