# frozen_string_literal: true

class FieldTranslationImport::ExtractTranslations < ApplicationInteractor
  def call
    context.translations = extract_translations_from_rows
  end

  private

  def extract_translations_from_rows
    return {} unless context.parsed_rows.any?

    translations = {
      buyer: {
        categories: {},
        subcategories: {},
        fields: {}
      },
      candidate: {
        categories: {},
        subcategories: {},
        fields: {}
      }
    }

    context.parsed_rows.each do |row|
      next unless row.should_import?

      extract_buyer_translations(row, translations[:buyer])
      extract_candidate_translations(row, translations[:candidate])

      increment_stat(:fields_processed)
    end

    update_statistics(translations)
    translations
  end

  def extract_buyer_translations(row, buyer_translations)
    extract_category_translation(row, buyer_translations, 'category_acheteur')
    extract_subcategory_translation(row, buyer_translations, 'subcategory_acheteur')
    extract_field_translations(row, buyer_translations, 'titre_acheteur', 'description_acheteur')
  end

  def extract_candidate_translations(row, candidate_translations)
    extract_category_translation(row, candidate_translations, 'category_candidat')
    extract_subcategory_translation(row, candidate_translations, 'subcategory_candidat')
    extract_field_translations(row, candidate_translations, 'titre_candidat', 'description_candidat')
  end

  def extract_category_translation(row, translations, column_name)
    return if row.category_key.blank?

    category_text = extract_raw_data(row, column_name)
    return if category_text.blank?

    translations[:categories][row.category_key] = category_text
  end

  def extract_subcategory_translation(row, translations, column_name)
    return if row.subcategory_key.blank?

    subcategory_text = extract_raw_data(row, column_name)
    return if subcategory_text.blank?

    translations[:subcategories][row.subcategory_key] = subcategory_text
  end

  def extract_field_translations(row, translations, name_column, description_column)
    return if row.key.blank?

    field_data = build_field_data(row, name_column, description_column)
    return if field_data.empty?

    translations[:fields][row.key] = field_data
  end

  def build_field_data(row, name_column, description_column)
    field_data = {}

    field_name = extract_raw_data(row, name_column)
    field_description = extract_raw_data(row, description_column)

    field_data[:name] = field_name.strip if field_name.present?
    field_data[:description] = field_description.strip if field_description.present?

    field_data
  end

  def extract_raw_data(row, column_name)
    return nil unless row.instance_variable_get(:@raw_data)

    raw_value = row.instance_variable_get(:@raw_data)[column_name]
    return nil if raw_value.blank?

    raw_value.strip
  end

  def update_statistics(translations)
    context.statistics[:categories_found] = count_unique_categories(translations)
    context.statistics[:subcategories_found] = count_unique_subcategories(translations)
  end

  def count_unique_categories(translations)
    buyer_categories = translations[:buyer][:categories].keys
    candidate_categories = translations[:candidate][:categories].keys
    (buyer_categories + candidate_categories).uniq.count
  end

  def count_unique_subcategories(translations)
    buyer_subcategories = translations[:buyer][:subcategories].keys
    candidate_subcategories = translations[:candidate][:subcategories].keys
    (buyer_subcategories + candidate_subcategories).uniq.count
  end

  def increment_stat(key)
    context.statistics[key] += 1
  end
end
