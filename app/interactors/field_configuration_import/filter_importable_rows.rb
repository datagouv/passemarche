# frozen_string_literal: true

class FieldConfigurationImport::FilterImportableRows < ApplicationInteractor
  def call
    context.importable_rows = []

    return unless context.parsed_rows

    context.parsed_rows.each do |row|
      increment_stat(:processed)

      if row.importable?
        context.importable_rows << row
      else
        increment_stat(:skipped)
        track_skipped_reason(row)
      end
    end
  end

  private

  def increment_stat(key)
    context.statistics[key] += 1
  end

  def track_skipped_reason(row)
    unless row.should_import?
      context.statistics[:skipped_not_requested] ||= 0
      context.statistics[:skipped_not_requested] += 1
      return
    end

    return unless row.errors.any?

    context.statistics[:skipped_validation_errors] ||= 0
    context.statistics[:skipped_validation_errors] += 1
  end
end
