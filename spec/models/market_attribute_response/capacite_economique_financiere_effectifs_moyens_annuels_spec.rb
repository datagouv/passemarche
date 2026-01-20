require 'rails_helper'

RSpec.describe MarketAttributeResponse::CapaciteEconomiqueFinanciereEffectifsMoyensAnnuels, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: :capacite_economique_financiere_effectifs_moyens_annuels) }

  subject(:response) do
    described_class.new(
      market_application:,
      market_attribute:,
      value:
    )
  end

  describe 'JSON schema validation' do
    context 'with valid complete data' do
      let(:value) do
        {
          'year_1' => { 'year' => 2024, 'average_staff' => 30, 'management_staff' => 5 },
          'year_2' => { 'year' => 2023, 'average_staff' => 32, 'management_staff' => 7 },
          'year_3' => { 'year' => 2022, 'average_staff' => 35, 'management_staff' => 8 }
        }
      end

      it { is_expected.to be_valid }
    end

    context 'with valid data without management_staff' do
      let(:value) do
        {
          'year_1' => { 'year' => 2024, 'average_staff' => 30 },
          'year_2' => { 'year' => 2023, 'average_staff' => 32 },
          'year_3' => { 'year' => 2022, 'average_staff' => 35 }
        }
      end

      it { is_expected.to be_valid }
    end

    context 'with partial year data' do
      let(:value) do
        {
          'year_1' => { 'year' => 2024, 'average_staff' => 30 },
          'year_2' => { 'year' => 2023, 'average_staff' => 32 }
        }
      end

      it 'is valid (partial data allowed)' do
        expect(response).to be_valid
      end
    end

    context 'with invalid year data structure' do
      let(:value) do
        {
          'year_1' => 'not a hash',
          'year_2' => { 'year' => 2023, 'average_staff' => 32 },
          'year_3' => { 'year' => 2022, 'average_staff' => 35 }
        }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1 must be a hash')
      end
    end
  end

  describe 'average_staff validation' do
    let(:base_value) do
      {
        'year_1' => { 'year' => 2024, 'average_staff' => 30 },
        'year_2' => { 'year' => 2023, 'average_staff' => 32 },
        'year_3' => { 'year' => 2022, 'average_staff' => 35 }
      }
    end

    context 'with missing average_staff (optional field)' do
      let(:value) do
        base_value.tap { |v| v['year_1'].delete('average_staff') }
      end

      it 'is valid' do
        expect(response).to be_valid
      end
    end

    context 'with negative average_staff' do
      let(:value) do
        base_value.tap { |v| v['year_1']['average_staff'] = -5 }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1.average_staff must be a positive integer')
      end
    end

    context 'with non-integer average_staff' do
      let(:value) do
        base_value.tap { |v| v['year_1']['average_staff'] = 'not_a_number' }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1.average_staff must be a positive integer')
      end
    end

    context 'with zero average_staff' do
      let(:value) do
        base_value.tap { |v| v['year_1']['average_staff'] = 0 }
      end

      it { is_expected.to be_valid }
    end
  end

  describe 'management_staff validation' do
    let(:base_value) do
      {
        'year_1' => { 'year' => 2024, 'average_staff' => 30, 'management_staff' => 5 },
        'year_2' => { 'year' => 2023, 'average_staff' => 32, 'management_staff' => 7 },
        'year_3' => { 'year' => 2022, 'average_staff' => 35, 'management_staff' => 8 }
      }
    end

    context 'with missing management_staff (optional field)' do
      let(:value) do
        base_value.tap { |v| v['year_1'].delete('management_staff') }
      end

      it 'is valid' do
        expect(response).to be_valid
      end
    end

    context 'with negative management_staff' do
      let(:value) do
        base_value.tap { |v| v['year_1']['management_staff'] = -5 }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1.management_staff must be a positive integer')
      end
    end

    context 'with non-integer management_staff' do
      let(:value) do
        base_value.tap { |v| v['year_1']['management_staff'] = 'not_a_number' }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1.management_staff must be a positive integer')
      end
    end

    context 'with zero management_staff' do
      let(:value) do
        base_value.tap { |v| v['year_1']['management_staff'] = 0 }
      end

      it { is_expected.to be_valid }
    end

    context 'with management_staff greater than average_staff (no constraint)' do
      let(:value) do
        base_value.tap { |v| v['year_1']['management_staff'] = 100 }
      end

      it { is_expected.to be_valid }
    end
  end

  describe 'year validation' do
    let(:base_value) do
      {
        'year_1' => { 'year' => 2024, 'average_staff' => 30 },
        'year_2' => { 'year' => 2023, 'average_staff' => 32 },
        'year_3' => { 'year' => 2022, 'average_staff' => 35 }
      }
    end

    context 'with missing year (optional field)' do
      let(:value) do
        base_value.tap { |v| v['year_1'].delete('year') }
      end

      it 'is valid' do
        expect(response).to be_valid
      end
    end

    context 'with year out of range' do
      let(:value) do
        base_value.tap { |v| v['year_1']['year'] = 1800 }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1.year must be a valid year')
      end
    end

    context 'with non-integer year' do
      let(:value) do
        base_value.tap { |v| v['year_1']['year'] = 'not_a_year' }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1.year must be a valid year')
      end
    end
  end

  describe 'virtual attributes' do
    let(:value) do
      {
        'year_1' => { 'year' => 2024, 'average_staff' => 30, 'management_staff' => 5 },
        'year_2' => { 'year' => 2023, 'average_staff' => 32, 'management_staff' => 7 }
      }
    end

    it 'provides getter methods for all year/field combinations' do
      expect(response.year_1_year).to eq(2024)
      expect(response.year_1_average_staff).to eq(30)
      expect(response.year_1_management_staff).to eq(5)
      expect(response.year_2_year).to eq(2023)
      expect(response.year_2_average_staff).to eq(32)
      expect(response.year_2_management_staff).to eq(7)
    end

    it 'allows setting values through virtual attributes' do
      response.year_3_year = '2022'
      response.year_3_average_staff = '35'
      response.year_3_management_staff = '8'
      expect(response.value['year_3']['year']).to eq(2022)
      expect(response.value['year_3']['average_staff']).to eq(35)
      expect(response.value['year_3']['management_staff']).to eq(8)
    end

    it 'converts string integers to integers for numeric fields' do
      response.year_1_year = '2025'
      response.year_1_average_staff = '40'
      response.year_1_management_staff = '10'
      expect(response.value['year_1']['year']).to be_an(Integer)
      expect(response.value['year_1']['average_staff']).to be_an(Integer)
      expect(response.value['year_1']['management_staff']).to be_an(Integer)
      expect(response.value['year_1']['year']).to eq(2025)
      expect(response.value['year_1']['average_staff']).to eq(40)
      expect(response.value['year_1']['management_staff']).to eq(10)
    end
  end

  describe 'class methods' do
    describe '.json_schema_properties' do
      it 'returns the expected properties' do
        expect(described_class.json_schema_properties).to eq(%w[year_1 year_2 year_3])
      end
    end

    describe '.json_schema_required' do
      it 'returns empty array to allow partial data' do
        expect(described_class.json_schema_required).to eq([])
      end
    end

    describe '.json_schema_error_field' do
      it 'returns :value as the error field' do
        expect(described_class.json_schema_error_field).to eq(:value)
      end
    end
  end
end
