# frozen_string_literal: true

module CategoryLabelHelper
  def category_label(key, scope:, default: nil)
    return default || key.to_s.humanize if key.blank?

    category = categories_by_key[key.to_s]
    category&.public_send(:"#{scope}_label").presence || default || key.to_s.humanize
  end

  def subcategory_label(key, scope:, default: nil)
    return default || key.to_s.humanize if key.blank?

    subcategory = subcategories_by_key[key.to_s]
    subcategory&.public_send(:"#{scope}_label").presence || default || key.to_s.humanize
  end

  private

  def categories_by_key
    @categories_by_key ||= Category.all.index_by(&:key)
  end

  def subcategories_by_key
    @subcategories_by_key ||= Subcategory.all.index_by(&:key)
  end
end
