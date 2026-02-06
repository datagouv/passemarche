# frozen_string_literal: true

class CategoryDataMigrationService < ApplicationServiceObject
  TRANSLATION_FILE = Rails.root.join('config/locales/form_fields.fr.yml')

  def perform
    translations = load_translations
    categories_created = 0
    subcategories_created = 0
    attributes_linked = 0

    ActiveRecord::Base.transaction do
      category_map = create_categories(translations)
      categories_created = category_map.size

      subcategory_map = create_subcategories(translations, category_map)
      subcategories_created = subcategory_map.size

      attributes_linked = backfill_market_attributes(subcategory_map)
    end

    @result = {
      categories_created:,
      subcategories_created:,
      attributes_linked:
    }
  end

  private

  def load_translations
    YAML.load_file(TRANSLATION_FILE).dig('fr', 'form_fields') || {}
  end

  def create_categories(translations)
    buyer_labels = translations.dig('buyer', 'categories') || {}
    candidate_labels = translations.dig('candidate', 'categories') || {}

    category_keys = MarketAttribute.distinct.pluck(:category_key)

    category_keys.each_with_index.with_object({}) do |(key, index), map|
      category = Category.find_or_initialize_by(key:)
      category.assign_attributes(
        buyer_label: buyer_labels[key],
        candidate_label: candidate_labels[key],
        position: index
      )
      category.save!
      map[key] = category
    end
  end

  def create_subcategories(translations, category_map)
    labels = subcategory_labels(translations)
    position_counters = Hash.new(0)

    unique_subcategory_pairs.each_with_object({}) do |(cat_key, sub_key), map|
      category = category_map[cat_key]
      next unless category

      subcategory = find_or_create_subcategory(category, sub_key, labels, position_counters[cat_key])
      position_counters[cat_key] += 1
      map[[cat_key, sub_key]] = subcategory
    end
  end

  def unique_subcategory_pairs
    MarketAttribute.distinct.pluck(:category_key, :subcategory_key)
  end

  def subcategory_labels(translations)
    {
      buyer: translations.dig('buyer', 'subcategories') || {},
      candidate: translations.dig('candidate', 'subcategories') || {}
    }
  end

  def find_or_create_subcategory(category, key, labels, position)
    subcategory = Subcategory.find_or_initialize_by(category:, key:)
    subcategory.assign_attributes(
      buyer_label: labels[:buyer][key],
      candidate_label: labels[:candidate][key],
      position:
    )
    subcategory.save!
    subcategory
  end

  def backfill_market_attributes(subcategory_map)
    count = 0
    MarketAttribute.find_each do |attr|
      subcategory = subcategory_map[[attr.category_key, attr.subcategory_key]]
      next unless subcategory
      next if attr.subcategory_id == subcategory.id

      attr.update!(subcategory:)
      count += 1
    end
    count
  end
end
