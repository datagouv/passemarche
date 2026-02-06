# frozen_string_literal: true

class FieldConfigurationImport::ImportFieldData < ApplicationInteractor
  def call
    context.imported_keys = []
    @category_cache = {}
    @subcategory_cache = {}

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

    subcategory = find_or_create_subcategory(row)
    update_market_attribute(market_attribute, row, subcategory)
    was_changed = market_attribute.saved_changes.present?
    update_market_type_associations(market_attribute, row)

    context.imported_keys << row.key
    track_creation_stats(was_new, was_changed)
  end

  def find_or_create_category(row)
    @category_cache[row.category_key] ||= begin
      category = Category.find_or_initialize_by(key: row.category_key)
      category.assign_attributes(
        buyer_label: row.category_acheteur&.strip.presence || category.buyer_label,
        candidate_label: row.category_candidat&.strip.presence || category.candidate_label
      )
      category.save!
      category
    end
  end

  def find_or_create_subcategory(row)
    cache_key = [row.category_key, row.subcategory_key]
    @subcategory_cache[cache_key] ||= persist_subcategory(row)
  end

  def persist_subcategory(row)
    category = find_or_create_category(row)
    subcategory = Subcategory.find_or_initialize_by(category:, key: row.subcategory_key)
    subcategory.assign_attributes(subcategory_labels_from(row, subcategory))
    subcategory.save!
    subcategory
  end

  def subcategory_labels_from(row, subcategory)
    {
      buyer_label: row.subcategory_acheteur&.strip.presence || subcategory.buyer_label,
      candidate_label: row.subcategory_candidat&.strip.presence || subcategory.candidate_label
    }
  end

  def update_market_attribute(market_attribute, row, subcategory)
    market_attribute.assign_attributes(row.to_market_attribute_params.merge(subcategory:))
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
