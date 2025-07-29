# frozen_string_literal: true

class PublicMarketPresenter
  def initialize(public_market)
    @public_market = public_market
    @service = FieldConfigurationService.new(
      market_type: public_market.market_type,
      defense_industry: public_market.defense_industry?
    )
  end

  def required_fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(@service.effective_required_fields)
  end

  def optional_fields_by_category_and_subcategory
    organize_fields_by_category_and_subcategory(@service.effective_optional_fields)
  end

  def all_fields_by_category_and_subcategory
    all_fields = @service.effective_required_fields + @service.effective_optional_fields
    organize_fields_by_category_and_subcategory(all_fields)
  end

  def should_display_subcategory?(subcategories)
    subcategories.keys.size > 1
  end

  def source_types
    I18n.t('form_fields.source_types')
  end

  delegate :field_by_key, to: :@service

  private

  def organize_fields_by_category_and_subcategory(fields)
    fields
      .group_by(&:category)
      .transform_values { |category_fields| group_by_subcategory(category_fields) }
  end

  def group_by_subcategory(fields)
    fields
      .group_by(&:subcategory)
      .transform_values { |subcategory_fields| subcategory_fields.map(&:key) }
  end
end
