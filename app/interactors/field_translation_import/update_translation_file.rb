# frozen_string_literal: true

require 'yaml'

class FieldTranslationImport::UpdateTranslationFile < ApplicationInteractor
  TRANSLATION_FILE_PATH = Rails.root.join('config/locales/form_fields.fr.yml')

  def call
    return unless context.translations

    existing_translations = load_existing_translations
    updated_translations = merge_translations(existing_translations, context.translations)

    write_translation_file(updated_translations)

    context.translation_file_path = translation_file_path
    context.statistics[:translation_file_updated] = true
  end

  private

  def translation_file_path
    context.translation_file_path || TRANSLATION_FILE_PATH
  end

  def load_existing_translations
    return default_translation_structure unless File.exist?(translation_file_path)

    begin
      YAML.safe_load_file(translation_file_path) || default_translation_structure
    rescue StandardError => e
      Rails.logger.warn "Failed to load existing translations: #{e.message}"
      default_translation_structure
    end
  end

  def default_translation_structure
    {
      'fr' => {
        'form_fields' => {
          'source_types' => {
            'authentic_source' => {
              'label' => 'Source authentique',
              'badge_class' => 'fr-badge--success'
            },
            'honor_declaration' => {
              'label' => 'Déclaration sur l\'honneur',
              'badge_class' => 'fr-badge--info'
            }
          },
          'categories' => {},
          'subcategories' => {},
          'fields' => {}
        }
      }
    }
  end

  def merge_translations(existing, new_translations)
    merged = existing.deep_dup
    ensure_form_fields_structure(merged)
    update_translation_sections(merged, new_translations)
    merged
  end

  def ensure_form_fields_structure(merged)
    merged['fr'] ||= {}
    merged['fr']['form_fields'] ||= {}
  end

  def update_translation_sections(merged, new_translations)
    form_fields = merged['fr']['form_fields']

    update_buyer_translations(form_fields, new_translations[:buyer])
    update_candidate_translations(form_fields, new_translations[:candidate])
  end

  def update_buyer_translations(form_fields, buyer_translations)
    form_fields['buyer'] ||= {}
    form_fields['buyer']['categories'] = buyer_translations[:categories]&.deep_stringify_keys || {}
    form_fields['buyer']['subcategories'] = buyer_translations[:subcategories]&.deep_stringify_keys || {}
    form_fields['buyer']['fields'] = buyer_translations[:fields]&.deep_stringify_keys || {}
  end

  def update_candidate_translations(form_fields, candidate_translations)
    form_fields['candidate'] ||= {}
    form_fields['candidate']['categories'] = candidate_translations[:categories]&.deep_stringify_keys || {}
    form_fields['candidate']['subcategories'] = candidate_translations[:subcategories]&.deep_stringify_keys || {}
    form_fields['candidate']['fields'] = candidate_translations[:fields]&.deep_stringify_keys || {}
  end

  def write_translation_file(translations)
    file_writer.write(translation_file_path, generate_yaml_content(translations))
  end

  def file_writer
    context.file_writer || File
  end

  def generate_yaml_content(translations)
    yaml_content = translations.to_yaml

    header = "# Form Fields French Translations\n# Auto-generated from CSV import\n\n"

    header + yaml_content
  end
end
