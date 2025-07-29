# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Field Configuration Integrity', type: :configuration do
  let(:service) { FieldConfigurationService.new(market_type: 'supplies', defense_industry: false) }
  let(:all_fields) { service.all_fields }
  let(:field_keys) { all_fields.map(&:key) }

  describe 'YAML configuration completeness' do
    it 'has all required field attributes' do
      all_fields.each do |field|
        expect(field.key).to be_present, "Field missing key: #{field.inspect}"
        expect(field.type).to be_present, "Field missing type: #{field.key}"
        expect(field.category).to be_present, "Field missing category: #{field.key}"
        expect(field.subcategory).to be_present, "Field missing subcategory: #{field.key}"
        expect(field.source_type).to be_present, "Field missing source_type: #{field.key}"
      end
    end

    it 'has valid field types' do
      valid_types = %w[document_upload text_field checkbox_field]
      all_fields.each do |field|
        expect(valid_types).to include(field.type),
          "Invalid field type '#{field.type}' for field '#{field.key}'. Valid types: #{valid_types}"
      end
    end

    it 'has valid source types' do
      valid_sources = %w[authentic_source honor_declaration]
      all_fields.each do |field|
        expect(valid_sources).to include(field.source_type),
          "Invalid source type '#{field.source_type}' for field '#{field.key}'. Valid sources: #{valid_sources}"
      end
    end

    it 'has valid market type associations' do
      valid_market_types = %w[supplies services works]
      all_fields.each do |field|
        (field.required_for + field.optional_for).each do |market_type|
          expect(valid_market_types).to include(market_type),
            "Invalid market type '#{market_type}' in field '#{field.key}'. Valid types: #{valid_market_types}"
        end
      end
    end
  end

  describe 'Translation completeness' do
    it 'has translations for all field names' do
      field_keys.each do |field_key|
        translation_key = "form_fields.fields.#{field_key}.name"
        translation = I18n.t(translation_key, locale: :fr, default: '__MISSING__')
        expect(translation).not_to eq('__MISSING__'),
          "Missing French translation for field name: #{translation_key}"
        expect(translation).not_to start_with('translation missing'),
          "Translation missing for field name: #{translation_key}"
      end
    end

    it 'has translations for all field descriptions' do
      field_keys.each do |field_key|
        translation_key = "form_fields.fields.#{field_key}.description"
        translation = I18n.t(translation_key, locale: :fr, default: '__MISSING__')
        expect(translation).not_to eq('__MISSING__'),
          "Missing French translation for field description: #{translation_key}"
        expect(translation).not_to start_with('translation missing'),
          "Translation missing for field description: #{translation_key}"
      end
    end

    it 'has translations for all categories' do
      categories = all_fields.map(&:category).uniq
      categories.each do |category|
        translation_key = "form_fields.categories.#{category}"
        translation = I18n.t(translation_key, locale: :fr, default: '__MISSING__')
        expect(translation).not_to eq('__MISSING__'),
          "Missing French translation for category: #{translation_key}"
        expect(translation).not_to start_with('translation missing'),
          "Translation missing for category: #{translation_key}"
      end
    end

    it 'has translations for all subcategories' do
      subcategories = all_fields.map(&:subcategory).uniq
      subcategories.each do |subcategory|
        translation_key = "form_fields.subcategories.#{subcategory}"
        translation = I18n.t(translation_key, locale: :fr, default: '__MISSING__')
        expect(translation).not_to eq('__MISSING__'),
          "Missing French translation for subcategory: #{translation_key}"
        expect(translation).not_to start_with('translation missing'),
          "Translation missing for subcategory: #{translation_key}"
      end
    end

    it 'has translations for all source types' do
      source_types = all_fields.map(&:source_type).uniq
      source_type_attributes = %w[label badge_class]
      source_types.each do |source_type|
        source_type_attributes.each do |attribute|
          translation_key = "form_fields.source_types.#{source_type}.#{attribute}"
          translation = I18n.t(translation_key, locale: :fr, default: '__MISSING__')
          expect(translation).not_to eq('__MISSING__'),
            "Missing French translation for source type #{attribute}: #{translation_key}"
          expect(translation).not_to start_with('translation missing'),
            "Translation missing for source type #{attribute}: #{translation_key}"
        end
      end
    end
  end

  describe 'Business logic consistency' do
    it 'has no duplicate field keys' do
      duplicate_keys = field_keys.group_by(&:itself).select { |_, v| v.size > 1 }.keys
      expect(duplicate_keys).to be_empty,
        "Duplicate field keys found: #{duplicate_keys}"
    end

    it 'has no fields that are both required and optional for the same market type' do
      all_fields.each do |field|
        overlap = field.required_for & field.optional_for
        expect(overlap).to be_empty,
          "Field '#{field.key}' is both required and optional for market types: #{overlap}"
      end
    end

    it 'has consistent category groupings' do
      # Fields in the same category should have related subcategories
      all_fields.group_by(&:category).each do |category, category_fields|
        subcategories = category_fields.map(&:subcategory).uniq
        expect(subcategories.size).to be >= 1,
          "Category '#{category}' has no subcategories"
        expect(subcategories.size).to be <= 5,
          "Category '#{category}' has too many subcategories (#{subcategories.size}), consider splitting"
      end
    end

    it 'has defense fields properly configured' do
      defense_required_fields = all_fields.select(&:required_for_defense?)
      defense_optional_fields = all_fields.select(&:optional_for_defense?)

      expect(defense_required_fields).not_to be_empty,
        'No defense required fields configured'
      expect(defense_optional_fields).not_to be_empty,
        'No defense optional fields configured'

      # Defense fields shouldn't overlap
      defense_required_keys = defense_required_fields.map(&:key)
      defense_optional_keys = defense_optional_fields.map(&:key)
      overlap = defense_required_keys & defense_optional_keys
      expect(overlap).to be_empty,
        "Fields cannot be both defense required and defense optional: #{overlap}"
    end
  end

  describe 'Market type coverage' do
    %w[supplies services works].each do |market_type|
      context "for #{market_type} market type" do
        let(:market_service) do
          FieldConfigurationService.new(market_type: market_type, defense_industry: false)
        end

        it 'has required fields configured' do
          required_fields = market_service.effective_required_fields
          expect(required_fields).not_to be_empty,
            "No required fields configured for market type '#{market_type}'"
        end

        it 'has optional fields configured' do
          optional_fields = market_service.effective_optional_fields
          expect(optional_fields).not_to be_empty,
            "No optional fields configured for market type '#{market_type}'"
        end

        it 'has at least one field per major category' do
          all_market_fields = market_service.effective_required_fields + market_service.effective_optional_fields
          categories = all_market_fields.map(&:category).uniq
          expect(categories.size).to be >= 2,
            "Market type '#{market_type}' should have fields from multiple categories, only has: #{categories}"
        end
      end
    end
  end

  describe 'Defense industry coverage' do
    %w[supplies services works].each do |market_type|
      context "for #{market_type} market type with defense industry" do
        let(:defense_service) do
          FieldConfigurationService.new(market_type: market_type, defense_industry: true)
        end
        let(:regular_service) do
          FieldConfigurationService.new(market_type: market_type, defense_industry: false)
        end

        it 'has additional required fields when defense industry is enabled' do
          defense_required = defense_service.effective_required_fields.map(&:key)
          regular_required = regular_service.effective_required_fields.map(&:key)

          additional_fields = defense_required - regular_required
          expect(additional_fields).not_to be_empty,
            "Defense industry should add required fields for market type '#{market_type}'"
        end

        it 'has additional optional fields when defense industry is enabled' do
          defense_optional = defense_service.effective_optional_fields.map(&:key)
          regular_optional = regular_service.effective_optional_fields.map(&:key)

          # Defense might add optional fields OR move some from required to optional
          expect(defense_optional.size).to be >= regular_optional.size,
            "Defense industry should not reduce optional fields for market type '#{market_type}'"
        end
      end
    end
  end
end
