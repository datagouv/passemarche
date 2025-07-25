# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicMarket, type: :model do
  describe 'associations' do
    it { should belong_to(:editor) }
  end

  describe 'identifier generation' do
    let(:editor) { create(:editor) }
    let(:public_market) { build(:public_market, editor: editor, identifier: nil) }

    it 'generates an identifier before validation on create' do
      expect(public_market.identifier).to be_nil
      public_market.valid?
      expect(public_market.identifier).to match(/^VR-\d{4}-[A-Z0-9]{12}$/)
    end
  end

  describe '#complete!' do
    let(:public_market) { create(:public_market, completed_at: nil) }

    it 'sets completed_at to current time' do
      time_before = Time.current
      public_market.complete!
      time_after = Time.current

      expect(public_market.completed_at).to be_between(time_before, time_after)
    end

    it 'persists the change' do
      public_market.complete!
      public_market.reload
      expect(public_market.completed_at).to be_present
    end
  end

  describe '#mark_form_configuration_completed!' do
    let(:public_market) { create(:public_market, completed_at: nil) }

    it 'should be false when nil' do
      expect(public_market.completed?).to be false
    end

    it 'defines completed_at' do
      public_market.mark_form_configuration_completed!
      public_market.reload
      expect(public_market.completed?).to be true
    end
  end

  describe 'FormFieldConfiguration concern' do
    let(:public_market) { create(:public_market, market_type: 'supplies', defense: false) }

    describe '#effective_required_fields' do
      context 'with supplies market type and no defense' do
        it 'returns market type specific required fields' do
          expected_fields = %w[unicorn_birth_certificate pizza_allergy_declaration coffee_addiction_level]
          expect(public_market.effective_required_fields).to eq(expected_fields)
        end
      end

      context 'with supplies market type and defense true' do
        before { public_market.update!(defense: true) }

        it 'returns union of market type and defense required fields' do
          expected_fields = %w[unicorn_birth_certificate pizza_allergy_declaration coffee_addiction_level ninja_stealth_certificate invisible_skill_proof]
          expect(public_market.effective_required_fields).to match_array(expected_fields)
        end
      end

      context 'with services market type' do
        before { public_market.update!(market_type: 'services') }

        it 'returns services specific required fields' do
          expected_fields = %w[unicorn_horn_measurement pineapple_pizza_stance]
          expect(public_market.effective_required_fields).to eq(expected_fields)
        end
      end

      context 'with works market type' do
        before { public_market.update!(market_type: 'works') }

        it 'returns works specific required fields' do
          expected_fields = %w[unicorn_birth_certificate croissant_eating_frequency ninja_stealth_certificate]
          expect(public_market.effective_required_fields).to eq(expected_fields)
        end
      end
    end

    describe '#effective_optional_fields' do
      context 'with supplies market type and no defense' do
        it 'returns market type specific optional fields' do
          expected_fields = %w[rocket_piloting_license ninja_stealth_certificate dragon_taming_permit]
          expect(public_market.effective_optional_fields).to eq(expected_fields)
        end
      end

      context 'with supplies market type and defense true' do
        before { public_market.update!(defense: true) }

        it 'returns union of market type and defense optional fields' do
          expected_fields = %w[rocket_piloting_license ninja_stealth_certificate dragon_taming_permit time_travel_authorization]
          expect(public_market.effective_optional_fields).to match_array(expected_fields)
        end
      end

      context 'with services market type' do
        before { public_market.update!(market_type: 'services') }

        it 'returns services specific optional fields' do
          expected_fields = %w[moon_landing_experience invisible_skill_proof time_travel_authorization]
          expect(public_market.effective_optional_fields).to eq(expected_fields)
        end
      end
    end

    describe '#fields_by_category' do
      let(:field_keys) { %w[unicorn_birth_certificate pizza_allergy_declaration rocket_piloting_license] }

      it 'groups fields by their categories' do
        result = public_market.fields_by_category(field_keys)

        expect(result).to eq({
          'unicorn_identity' => ['unicorn_birth_certificate'],
          'pizza_exclusions' => ['pizza_allergy_declaration'],
          'rocket_certifications' => ['rocket_piloting_license']
        })
      end

      it 'handles empty field list' do
        result = public_market.fields_by_category([])
        expect(result).to eq({})
      end

      it 'ignores unknown field keys' do
        result = public_market.fields_by_category(['unknown_field'])
        expect(result).to eq({})
      end
    end
  end

  describe 'selected_optional_fields' do
    let(:public_market) { create(:public_market) }

    it 'defaults to empty array' do
      expect(public_market.selected_optional_fields).to eq([])
    end
  end
end
