# frozen_string_literal: true

class FieldTranslationImport < ApplicationOrganizer
  organize FieldConfigurationImport::ValidateCsvFile,
    FieldTranslationImport::CleanCsvFile,
    FieldConfigurationImport::ParseCsvFile,
    FieldTranslationImport::ExtractTranslations,
    FieldTranslationImport::UpdateTranslationFile,
    FieldTranslationImport::BuildTranslationStatistics

  def self.call(context = {})
    context[:statistics] ||= default_statistics
    context[:translations] ||= initialize_translations
    context[:warnings] ||= []
    context[:translation_file_updated] ||= false

    super
  end

  private_class_method def self.default_statistics
    {
      processed: 0,
      skipped: 0,
      fields_processed: 0,
      categories_found: 0,
      subcategories_found: 0,
      translation_file_updated: false
    }
  end

  private_class_method def self.initialize_translations
    {
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
  end
end
