# frozen_string_literal: true

class FieldTranslationImport::BuildTranslationStatistics < ApplicationInteractor
  def call
    return unless context.translations

    build_final_statistics
    validate_translations
  end

  private

  def build_final_statistics
    context.statistics.merge!(
      total_categories: combined_keys_from_both_contexts(:categories).count,
      total_subcategories: combined_keys_from_both_contexts(:subcategories).count,
      total_fields: combined_keys_from_both_contexts(:fields).count,
      fields_with_names: count_fields_with(:name),
      fields_with_descriptions: count_fields_with(:description)
    )
  end

  def combined_keys_from_both_contexts(key)
    buyer_keys = context.translations[:buyer][key]&.keys || []
    candidate_keys = context.translations[:candidate][key]&.keys || []
    (buyer_keys + candidate_keys).uniq
  end

  def count_fields_with(attribute)
    combined_fields_from_both_contexts.count do |_key, field_data|
      field_data.is_a?(Hash) && field_data[attribute].present?
    end
  end

  def combined_fields_from_both_contexts
    buyer_fields = context.translations[:buyer][:fields] || {}
    candidate_fields = context.translations[:candidate][:fields] || {}
    buyer_fields.merge(candidate_fields)
  end

  def validate_translations
    warnings = []

    warnings << 'No category translations found' if all_empty?(:categories)
    warnings << 'No subcategory translations found' if all_empty?(:subcategories)

    incomplete_count = count_incomplete_fields
    warnings << "#{incomplete_count} fields have no translations" if incomplete_count.positive?

    context.statistics[:warnings] = warnings
  end

  def all_empty?(key)
    buyer_data = context.translations[:buyer][key] || {}
    candidate_data = context.translations[:candidate][key] || {}
    buyer_data.empty? && candidate_data.empty?
  end

  def count_incomplete_fields
    combined_fields_from_both_contexts.count do |_key, field_data|
      next true unless field_data.is_a?(Hash)

      field_data[:name].blank? && field_data[:description].blank?
    end
  end
end
