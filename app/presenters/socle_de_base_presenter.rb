# frozen_string_literal: true

class SocleDeBasePresenter
  def initialize(market_attribute)
    @market_attribute = market_attribute
  end

  def buyer_name
    I18n.t("form_fields.buyer.fields.#{key}.name", default: key.humanize)
  end

  def buyer_description
    I18n.t("form_fields.buyer.fields.#{key}.description", default: nil)
  end

  def candidate_name
    I18n.t("form_fields.candidate.fields.#{key}.name", default: key.humanize)
  end

  def candidate_description
    I18n.t("form_fields.candidate.fields.#{key}.description", default: nil)
  end

  def buyer_category_label
    I18n.t("form_fields.buyer.categories.#{category_key}", default: category_key.humanize)
  end

  def buyer_subcategory_label
    I18n.t("form_fields.buyer.subcategories.#{subcategory_key}", default: subcategory_key.humanize)
  end

  def candidate_category_label
    I18n.t("form_fields.candidate.categories.#{category_key}", default: category_key.humanize)
  end

  def candidate_subcategory_label
    I18n.t("form_fields.candidate.subcategories.#{subcategory_key}", default: subcategory_key.humanize)
  end

  def mandatory_badge
    mandatory? ? I18n.t('admin.socle_de_base.badges.mandatory') : I18n.t('admin.socle_de_base.badges.optional')
  end

  def mandatory_badge_class
    mandatory? ? 'fr-badge--info' : 'fr-badge--new'
  end

  def source_badge
    from_api? ? I18n.t('admin.socle_de_base.badges.api', api_name:) : I18n.t('admin.socle_de_base.badges.manual')
  end

  def source_badge_class
    from_api? ? 'fr-badge--success' : 'fr-badge--warning'
  end

  private

  def key
    @market_attribute.key
  end

  def category_key
    @market_attribute.category_key
  end

  def subcategory_key
    @market_attribute.subcategory_key
  end

  def mandatory?
    @market_attribute.mandatory
  end

  def from_api?
    @market_attribute.from_api?
  end

  def api_name
    @market_attribute.api_name
  end
end
