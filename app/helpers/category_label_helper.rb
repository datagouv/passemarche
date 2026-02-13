# frozen_string_literal: true

module CategoryLabelHelper
  def category_label(key, role:)
    record_label(Category, key, role, :categories)
  end

  def subcategory_label(key, role:)
    record_label(Subcategory, key, role, :subcategories)
  end

  private

  def record_label(model_class, key, role, i18n_scope)
    return key.to_s.humanize if key.blank?

    record = active_records_cache(model_class)[key.to_s]
    label = record&.public_send(:"#{role}_label")

    label.presence || I18n.t("form_fields.#{role}.#{i18n_scope}.#{key}", default: key.to_s.humanize)
  end

  def active_records_cache(model_class)
    cache_var = :"@_#{model_class.name.underscore}_cache"

    if instance_variable_defined?(cache_var)
      instance_variable_get(cache_var)
    else
      instance_variable_set(cache_var, model_class.active.index_by(&:key))
    end
  end
end
