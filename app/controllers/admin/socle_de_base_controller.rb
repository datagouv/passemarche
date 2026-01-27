# frozen_string_literal: true

class Admin::SocleDeBaseController < Admin::ApplicationController
  def index
    @current_tab = current_tab
    @market_attributes = filtered_market_attributes
    @market_types = MarketType.active.order(:code)
  end

  private

  def current_tab
    tab = params[:tab]
    return MarketAttribute::CATEGORY_TABS.first if tab.blank?
    return MarketAttribute::CATEGORY_TABS.first unless MarketAttribute::CATEGORY_TABS.include?(tab)

    tab
  end

  def filtered_market_attributes
    scope = MarketAttribute.active.includes(:market_types).ordered
    scope = apply_tab_filter(scope)
    scope = apply_search_filter(scope)
    scope = apply_market_type_filter(scope)
    scope = apply_source_filter(scope)
    apply_mandatory_filter(scope)
  end

  def apply_tab_filter(scope)
    scope.by_category(@current_tab)
  end

  def apply_search_filter(scope)
    return scope if params[:q].blank?

    scope.where('key ILIKE ?', "%#{params[:q]}%")
  end

  def apply_market_type_filter(scope)
    return scope if params[:market_type_id].blank?

    scope.by_market_type(params[:market_type_id])
  end

  def apply_source_filter(scope)
    return scope if params[:source].blank?

    scope.by_source(params[:source])
  end

  def apply_mandatory_filter(scope)
    return scope if params[:mandatory].blank?

    params[:mandatory] == 'true' ? scope.mandatory : scope.optional
  end
end
