# frozen_string_literal: true

class SocleDeBasePresenter
  def initialize(market_attribute)
    @market_attribute = market_attribute
  end

  delegate :resolved_buyer_name, :resolved_buyer_description,
    :resolved_candidate_name, :resolved_candidate_description,
    to: :@market_attribute

  alias buyer_name resolved_buyer_name
  alias buyer_description resolved_buyer_description
  alias candidate_name resolved_candidate_name
  alias candidate_description resolved_candidate_description

  def buyer_category_label
    subcategory&.category&.buyer_label || category_key.humanize
  end

  def buyer_subcategory_label
    subcategory&.buyer_label || subcategory_key.humanize
  end

  def candidate_category_label
    subcategory&.category&.candidate_label || category_key.humanize
  end

  def candidate_subcategory_label
    subcategory&.candidate_label || subcategory_key.humanize
  end

  def mandatory_badge
    mandatory? ? I18n.t('admin.socle_de_base.badges.mandatory') : I18n.t('admin.socle_de_base.badges.optional')
  end

  def mandatory_badge_class
    mandatory? ? 'fr-badge--warning' : 'fr-badge--new'
  end

  def source_badge
    from_api? ? I18n.t('admin.socle_de_base.badges.api', api_name:) : I18n.t('admin.socle_de_base.badges.manual')
  end

  def source_badge_class
    from_api? ? 'fr-badge--success' : 'fr-badge--info'
  end

  alias category_label buyer_category_label
  alias subcategory_label buyer_subcategory_label
  alias field_name buyer_name

  MARKET_TYPE_BADGES = [
    { letter: 'T', code: 'works' },
    { letter: 'F', code: 'supplies' },
    { letter: 'S', code: 'services' },
    { letter: 'D', code: 'defense' }
  ].freeze

  def market_type_badges
    active_codes = @market_attribute.market_types.map(&:code)

    MARKET_TYPE_BADGES.map do |badge|
      badge.merge(active: active_codes.include?(badge[:code]))
    end
  end

  def input_type_label
    @market_attribute.input_type.humanize
  end

  delegate :key, :category_key, :subcategory_key, :subcategory, :mandatory?, :from_api?, :api_name, :api_key,
    :market_types, to: :@market_attribute
end
