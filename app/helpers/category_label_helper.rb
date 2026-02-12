# frozen_string_literal: true

module CategoryLabelHelper
  def buyer_category_label(category_key)
    category = Category.find_by(key: category_key)
    category&.buyer_label.presence || I18n.t("form_fields.buyer.categories.#{category_key}", default: category_key.humanize)
  end

  def candidate_category_label(category_key)
    category = Category.find_by(key: category_key)
    category&.candidate_label.presence || I18n.t("form_fields.candidate.categories.#{category_key}", default: category_key.humanize)
  end

  def buyer_subcategory_label(subcategory_key)
    subcategory = Subcategory.find_by(key: subcategory_key)
    subcategory&.buyer_label.presence || I18n.t("form_fields.buyer.subcategories.#{subcategory_key}", default: subcategory_key.humanize)
  end

  def candidate_subcategory_label(subcategory_key)
    subcategory = Subcategory.find_by(key: subcategory_key)
    subcategory&.candidate_label.presence || I18n.t("form_fields.candidate.subcategories.#{subcategory_key}", default: subcategory_key.humanize)
  end
end
