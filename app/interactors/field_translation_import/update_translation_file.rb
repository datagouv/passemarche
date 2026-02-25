# frozen_string_literal: true

class FieldTranslationImport::UpdateTranslationFile < ApplicationInteractor
  def call
    context.statistics[:translation_file_updated] = false
  end
end
