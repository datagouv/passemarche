# frozen_string_literal: true

class FieldConfigurationImport < ApplicationOrganizer
  organize FieldConfigurationImport::ValidateCsvFile,
    FieldTranslationImport::CleanCsvFile,
    FieldConfigurationImport::ParseCsvFile,
    FieldConfigurationImport::FilterImportableRows,
    FieldConfigurationImport::ImportFieldData,
    FieldConfigurationImport::SoftDeleteMissingFields,
    FieldConfigurationImport::BuildFinalStatistics

  def self.call(context = {})
    context[:statistics] ||= default_statistics

    super
  end

  private_class_method def self.default_statistics
    {
      processed: 0,
      created: 0,
      updated: 0,
      skipped: 0,
      soft_deleted: 0
    }
  end
end
