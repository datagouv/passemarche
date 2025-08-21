# frozen_string_literal: true

class FieldConfigurationImport::SoftDeleteMissingFields < ApplicationInteractor
  def call
    # rubocop:disable Rails/SkipsModelValidations
    deleted_count = MarketAttribute
      .where.not(key: context.imported_keys)
      .where(deleted_at: nil)
      .update_all(deleted_at: Time.current)
    # rubocop:enable Rails/SkipsModelValidations

    context.statistics[:soft_deleted] = deleted_count
  end
end
