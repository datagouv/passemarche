# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FieldsValidation, type: :concern do
  before do
    class TestFieldsValidation
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations
      include ActiveModel::Dirty

      extend ActiveModel::Callbacks

      define_model_callbacks :save

      include FieldsValidation

      attribute :market_type, :string, default: 'supplies'
      attribute :defense_industry, :boolean, default: false
      attribute :selected_optional_fields, default: -> { [] }

      def defense_industry?
        defense_industry
      end

      def save
        run_callbacks :save do
          true
        end
      end
    end
  end

  after do
    Object.send(:remove_const, :TestFieldsValidation) if defined?(TestFieldsValidation)
  end

  let(:instance) { TestFieldsValidation.new }

  describe 'validations' do
    context 'with valid configuration' do
      before do
        instance.defense_industry = true # Enable defense for optional fields
        instance.selected_optional_fields = %w[annual_turnover average_annual_workforce]
      end

      it 'is valid' do
        expect(instance).to be_valid
      end
    end

    context 'with empty selected_optional_fields' do
      before do
        instance.selected_optional_fields = []
      end

      it 'is valid with empty array' do
        expect(instance).to be_valid
      end
    end

    describe '#selected_fields_are_valid_keys' do
      context 'with invalid field keys' do
        before do
          instance.selected_optional_fields = %w[invalid_field another_invalid]
        end

        it 'adds validation error' do
          expect(instance).not_to be_valid
          expect(instance.errors[:selected_optional_fields]).to include(
            'contains invalid field keys: invalid_field, another_invalid'
          )
        end
      end

      context 'with valid field keys' do
        before do
          instance.selected_optional_fields = ['annual_turnover']
        end

        it 'does not add validation error' do
          instance.valid?
          expect(instance.errors[:selected_optional_fields]).not_to include(
            a_string_matching(/contains invalid field keys/)
          )
        end
      end
    end

    describe '#selected_fields_are_available_for_market_type' do
      context 'when field is not available for market type' do
        before do
          instance.market_type = 'supplies'
          instance.selected_optional_fields = ['qualiopi_certificate'] # Only available for services
        end

        it 'adds validation error' do
          expect(instance).not_to be_valid
          expect(instance.errors[:selected_optional_fields]).to include(
            a_string_matching(/contains fields not available for market type 'supplies'/)
          )
        end
      end

      context 'when field is available for market type' do
        before do
          instance.market_type = 'supplies'
          instance.selected_optional_fields = ['annual_turnover']
        end

        it 'does not add validation error' do
          instance.valid?
          expect(instance.errors[:selected_optional_fields]).not_to include(
            a_string_matching(/contains fields not available for market type/)
          )
        end
      end
    end

    describe '#selected_fields_are_appropriate_for_defense_status' do
      context 'when defense fields are selected without defense industry' do
        before do
          instance.defense_industry = false
          instance.selected_optional_fields = ['company_category']
        end

        it 'adds validation error' do
          expect(instance).not_to be_valid
          expect(instance.errors[:selected_optional_fields]).to include(
            a_string_matching(/contains fields not available for market type 'supplies' without defense industry/)
          )
        end
      end

      context 'when defense fields are selected with defense industry enabled' do
        before do
          instance.defense_industry = true
          instance.selected_optional_fields = ['company_category']
        end

        it 'does not add validation error' do
          instance.valid?
          expect(instance.errors[:selected_optional_fields]).not_to include(
            a_string_matching(/contains defense industry fields but defense_industry is false/)
          )
        end
      end
    end

    describe '#no_duplicate_selected_fields' do
      context 'with duplicate fields' do
        before do
          instance.selected_optional_fields = %w[rocket_piloting_license rocket_piloting_license ninja_stealth_certificate]
        end

        it 'adds validation error' do
          expect(instance).not_to be_valid
          expect(instance.errors[:selected_optional_fields]).to include(
            'contains duplicate entries: rocket_piloting_license'
          )
        end
      end

      context 'without duplicate fields' do
        before do
          instance.selected_optional_fields = %w[rocket_piloting_license ninja_stealth_certificate]
        end

        it 'does not add validation error' do
          instance.valid?
          expect(instance.errors[:selected_optional_fields]).not_to include(
            a_string_matching(/contains duplicate entries/)
          )
        end
      end
    end
  end

  describe 'normalization' do
    describe '#normalize_selected_optional_fields' do
      it 'removes nils and blanks' do
        instance.selected_optional_fields = ['rocket_piloting_license', nil, '', 'ninja_stealth_certificate']
        instance.save
        expect(instance.selected_optional_fields).to eq(%w[ninja_stealth_certificate rocket_piloting_license])
      end

      it 'removes duplicates' do
        instance.selected_optional_fields = %w[rocket_piloting_license rocket_piloting_license ninja_stealth_certificate]
        instance.save
        expect(instance.selected_optional_fields).to eq(%w[ninja_stealth_certificate rocket_piloting_license])
      end

      it 'converts to strings' do
        instance.selected_optional_fields = %i[rocket_piloting_license ninja_stealth_certificate]
        instance.save
        expect(instance.selected_optional_fields).to eq(%w[ninja_stealth_certificate rocket_piloting_license])
      end

      it 'sorts the array' do
        instance.selected_optional_fields = %w[ninja_stealth_certificate rocket_piloting_license]
        instance.save
        expect(instance.selected_optional_fields).to eq(%w[ninja_stealth_certificate rocket_piloting_license])
      end

      it 'handles empty arrays' do
        instance.selected_optional_fields = []
        instance.save
        expect(instance.selected_optional_fields).to eq([])
      end
    end
  end

  describe 'private methods' do
    describe '#field_configuration_service' do
      it 'creates service with correct parameters' do
        instance.market_type = 'works'
        instance.defense_industry = true

        service = instance.send(:field_configuration_service)
        expect(service).to be_a(FieldConfigurationService)
      end

      it 'memoizes the service instance' do
        service1 = instance.send(:field_configuration_service)
        service2 = instance.send(:field_configuration_service)
        expect(service1).to be(service2)
      end
    end
  end
end
