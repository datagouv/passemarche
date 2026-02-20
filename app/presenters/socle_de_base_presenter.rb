# frozen_string_literal: true

class SocleDeBasePresenter
  def initialize(market_attribute)
    @market_attribute = market_attribute
  end

  def buyer_name
    @market_attribute.buyer_name.presence || I18n.t("form_fields.buyer.fields.#{key}.name", default: key.humanize)
  end

  def buyer_description
    @market_attribute.buyer_description.presence || I18n.t("form_fields.buyer.fields.#{key}.description", default: nil)
  end

  def candidate_name
    @market_attribute.candidate_name.presence || I18n.t("form_fields.candidate.fields.#{key}.name", default: key.humanize)
  end

  def candidate_description
    @market_attribute.candidate_description.presence || I18n.t("form_fields.candidate.fields.#{key}.description", default: nil)
  end

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

  delegate :key, :category_key, :subcategory_key, :subcategory, :mandatory?, :from_api?, :api_name, to: :@market_attribute
end
