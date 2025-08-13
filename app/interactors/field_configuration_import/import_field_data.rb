# frozen_string_literal: true

class FieldConfigurationImport::ImportFieldData < ApplicationInteractor
  def call
    context.imported_keys = []

    return unless context.importable_rows

    ActiveRecord::Base.transaction do
      context.importable_rows.each do |row|
        import_single_row(row)
      end
    end
  end

  private

  def import_single_row(row)
    market_attribute = MarketAttribute.find_or_initialize_by(key: row.key)
    was_new = market_attribute.new_record?

    update_market_attribute(market_attribute, row)
    was_changed = market_attribute.saved_changes.present?
    update_market_type_associations(market_attribute, row)

    context.imported_keys << row.key
    track_creation_stats(was_new, was_changed)
  end

  def update_market_attribute(market_attribute, row)
    market_attribute.assign_attributes(row.to_market_attribute_params)
    market_attribute.save!
  end

  def update_market_type_associations(market_attribute, row)
    market_attribute.market_types.clear

    row.applicable_market_types.each do |market_type_code|
      market_type = MarketType.find_by(code: market_type_code)

      if market_type
        market_attribute.market_types << market_type
      else
        add_missing_market_type(market_type_code)
      end
    end
  end

  def track_creation_stats(was_new, was_changed)
    if was_new
      increment_stat(:created)
    elsif was_changed
      increment_stat(:updated)
    end
  end

  def increment_stat(key)
    context.statistics[key] += 1
  end

  def add_missing_market_type(code)
    context.statistics[:missing_market_types] ||= []
    context.statistics[:missing_market_types] << code
  end
end
