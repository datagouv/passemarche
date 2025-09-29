# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::CapacitesTechniquesProfessionnellesEffectifsCvIntervenants, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: :capacites_techniques_professionnelles_effectifs_cv_intervenants) }

  subject(:response) do
    described_class.new(
      market_application:,
      market_attribute:,
      value:
    )
  end

  describe 'associations' do
    let(:value) { {} }

    it { is_expected.to belong_to(:market_application) }
    it { is_expected.to belong_to(:market_attribute) }
  end

  describe 'includes' do
    let(:value) { {} }

    it 'includes FileAttachable concern' do
      expect(described_class.included_modules).to include(MarketAttributeResponse::FileAttachable)
    end

    it 'includes JsonValidatable concern' do
      expect(described_class.included_modules).to include(MarketAttributeResponse::JsonValidatable)
    end
  end

  describe 'JSON schema validation' do
    context 'with empty value' do
      let(:value) { nil }

      it { is_expected.to be_valid }
    end

    context 'with empty hash' do
      let(:value) { {} }

      it { is_expected.to be_valid }
    end

    context 'with valid persons data' do
      let(:value) do
        {
          'persons' => [
            {
              'nom' => 'Dupont',
              'prenoms' => 'Jean',
              'titres' => 'Ingénieur',
              'cv_attachment_id' => '123'
            },
            {
              'nom' => 'Martin',
              'prenoms' => 'Marie',
              'titres' => 'Architecte',
              'cv_attachment_id' => '456'
            }
          ]
        }
      end

      it { is_expected.to be_valid }
    end

    context 'with invalid persons type' do
      let(:value) do
        {
          'persons' => 'invalid string'
        }
      end

      it { is_expected.to be_invalid }

      it 'adds validation error' do
        response.valid?
        expect(response.errors[:value]).to include('persons must be an array')
      end
    end

    context 'with person missing nom' do
      let(:value) do
        {
          'persons' => [
            {
              'prenoms' => 'Jean',
              'titres' => 'Ingénieur'
            }
          ]
        }
      end

      it { is_expected.to be_invalid }

      it 'adds validation error' do
        response.valid?
        expect(response.errors[:value]).to include('Person at index 0: nom is required when person data is provided')
      end
    end

    context 'with empty person entry' do
      let(:value) do
        {
          'persons' => [{}]
        }
      end

      it { is_expected.to be_valid }
    end
  end

  describe '#persons' do
    context 'when value is nil' do
      let(:value) { nil }

      it 'returns empty array' do
        expect(response.persons).to eq([])
      end
    end

    context 'when persons exists' do
      let(:value) do
        {
          'persons' => [
            { 'nom' => 'Dupont', 'prenoms' => 'Jean' }
          ]
        }
      end

      it 'returns persons array' do
        expect(response.persons).to eq([{ 'nom' => 'Dupont', 'prenoms' => 'Jean' }])
      end
    end
  end

  describe '#persons=' do
    let(:value) { nil }

    it 'sets persons array in value' do
      persons_data = [{ 'nom' => 'Dupont', 'prenoms' => 'Jean' }]
      response.persons = persons_data
      expect(response.value['persons']).to eq(persons_data)
    end

    it 'handles non-array input' do
      response.persons = 'invalid'
      expect(response.value['persons']).to eq([])
    end
  end
end
