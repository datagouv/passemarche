# frozen_string_literal: true

class PublicMarketPresenter
  include SidemenuHelper
  include MarketAttributeGrouping

  INITIAL_WIZARD_STEP = :setup
  FINAL_WIZARD_STEP = :summary

  def initialize(public_market)
    @public_market = public_market
  end

  def wizard_steps
    [INITIAL_WIZARD_STEP] + available_category_keys.map(&:to_sym) + [FINAL_WIZARD_STEP]
  end

  def stepper_steps
    available_category_keys.map(&:to_sym) + [FINAL_WIZARD_STEP]
  end

  def parent_category_for(step_key)
    step_str = step_key.to_s
    return step_str if available_category_keys.include?(step_str)

    available_attributes_array
      .select { |attr| attr.subcategory_key == step_str }
      .filter_map(&:category_key)
      .first
  end

  def subcategories_for_category(category_key)
    return [] if category_key.blank?

    available_attributes_array
      .select { |attr| attr.category_key == category_key.to_s }
      .filter_map(&:subcategory_key)
      .uniq
  end

  def mandatory_fields_for_category(category_key)
    attrs = available_attributes_array.select { |a| a.mandatory && a.category_key == category_key.to_s }
    group_by_subcategory(attrs)
  end

  def optional_fields_for_category(category_key)
    attrs = available_attributes_array.select { |a| !a.mandatory && a.category_key == category_key.to_s }
    group_by_subcategory(attrs)
  end

  def optional_fields_for_category?(category_key)
    available_attributes_array.any? { |a| !a.mandatory && a.category_key == category_key.to_s }
  end

  def available_mandatory_fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(available_mandatory_market_attributes)
  end

  def available_optional_fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(available_optional_market_attributes)
  end

  def all_fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(all_market_attributes)
  end

  def mandatory_fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(all_market_attributes.mandatory)
  end

  def optional_fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(all_market_attributes.optional)
  end

  # Returns selected market attributes organized by category and subcategory
  # Categories are ordered by ID (same order as CSV import)
  def selected_fields_by_category_and_subcategory
    @selected_fields_by_category_and_subcategory ||= organize_selected_fields_by_category_and_subcategory(selected_market_attributes_ordered)
  end

  # Returns the category keys for selected attributes in the correct order
  def selected_category_keys
    @selected_category_keys ||= selected_market_attributes_ordered
      .filter_map(&:category_key)
      .uniq
  end

  def should_display_subcategory?(subcategories)
    subcategories.keys.size > 1
  end

  def source_types
    I18n.t('form_fields.source_types')
  end

  def field_by_key(key)
    MarketAttribute.find_by(key: key.to_s)
  end

  def available_mandatory_market_attributes
    available_attributes.mandatory
  end

  private

  def available_optional_market_attributes
    available_attributes.optional
  end

  def all_market_attributes
    @public_market.market_attributes.active.ordered
  end

  # Returns selected market attributes ordered by ID (preserves CSV import order)
  def selected_market_attributes_ordered
    @selected_market_attributes_ordered ||= @public_market.market_attributes.active.order(:id).to_a
  end

  # Organizes fields maintaining category order from selected_category_keys
  def organize_selected_fields_by_category_and_subcategory(market_attributes)
    grouped = market_attributes.group_by(&:category_key)

    selected_category_keys.each_with_object({}) do |category_key, result|
      next unless grouped[category_key]

      result[category_key] = group_by_subcategory(grouped[category_key])
    end
  end

  # Use order(:id) to maintain the same category order as the candidate flow
  # This ensures categories appear in the order they were defined in the CSV import
  def available_category_keys
    @available_category_keys ||= available_attributes_ordered_by_id
      .filter_map(&:category_key)
      .uniq
  end

  def available_attributes_array
    @available_attributes_array ||= available_attributes.to_a
  end

  # Query available attributes ordered by ID (like candidate flow)
  # Uses a subquery to avoid PostgreSQL DISTINCT + ORDER BY incompatibility
  def available_attributes_ordered_by_id
    @available_attributes_ordered_by_id ||= begin
      ids = MarketAttribute.joins(:market_types)
        .where(market_types: { code: @public_market.market_type_codes })
        .where(deleted_at: nil)
        .select(:id)
        .distinct

      MarketAttribute.where(id: ids).order(:id).to_a
    end
  end

  def organize_fields_by_category_and_subcategory(market_attributes)
    market_attributes
      .group_by(&:category_key)
      .transform_values { |category_attrs| group_by_subcategory(category_attrs) }
  end

  def available_attributes
    @available_attributes ||= MarketAttributeFilteringService.call(@public_market)
  end
end
