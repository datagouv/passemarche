# frozen_string_literal: true

class FieldTranslationImportService < ApplicationServiceObject
  def initialize(csv_file_path: Rails.root.join('config/form_fields/fields.csv'), **)
    super(**)
    @csv_file_path = csv_file_path
  end

  def perform
    context = Interactor::Context.build(csv_file_path: @csv_file_path)
    result = FieldTranslationImport.call(context)

    if result.success?
      @result = result.statistics
    else
      add_error(:import, result.message || 'Translation import failed')
      @result = nil
    end
  end
end
