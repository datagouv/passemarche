# frozen_string_literal: true

class MarketAttributeResponse::BaseComponent < ViewComponent::Base
  attr_reader :market_attribute_response, :form, :context, :scopes

  delegate :market_attribute, to: :market_attribute_response
  delegate :auto?, :manual_after_api_failure?, to: :market_attribute_response

  def initialize(market_attribute_response:, form: nil, context: :web, scopes: [])
    @market_attribute_response = market_attribute_response
    @form = form
    @context = context
    @scopes = scopes || []
  end

  def scope_tags_html
    return if @scopes.blank?

    helpers.content_tag(:span, helpers.safe_join(@scopes.map { |scope| scope_tag(scope) }), class: 'market-scope-tags')
  end

  def scope_tag(scope)
    if scope == :commun
      commun_scope_tag
    else
      helpers.market_type_badge_tag(scope.to_s, I18n.t("market_types.#{scope}", default: scope.to_s.humanize))
    end
  end

  def commun_scope_tag
    label = I18n.t('buyer.public_markets.form_config.scope_commun_badge')
    icon = helpers.content_tag(:span, '', class: 'fr-icon-links-fill fr-icon--xs fr-mr-1v', aria: { hidden: true })
    helpers.content_tag(:span, icon + label, class: 'fr-tag fr-tag--sm market-scope-tag')
  end

  def form_mode?
    form.present?
  end

  def display_mode?
    !form_mode?
  end

  def manual?
    market_attribute_response.manual? || market_attribute_response.manual_after_api_failure?
  end

  def show_value?
    !auto? || context == :buyer
  end

  def field_label
    market_attribute.resolved_candidate_name
  end

  def field_label_with_scope
    return field_label if @scopes.blank?

    helpers.safe_join([field_label, scope_tags_html])
  end

  def field_description
    market_attribute.resolved_candidate_description
  end

  def auto_filled_message
    I18n.t('candidate.market_applications.auto_filled_message')
  end

  def source_badge_component
    SourceBadgeComponent.new(market_attribute_response:, context:)
  end
end
