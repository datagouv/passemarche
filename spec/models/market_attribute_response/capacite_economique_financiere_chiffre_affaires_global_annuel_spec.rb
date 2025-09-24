# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::CapaciteEconomiqueFinanciereChiffreAffairesGlobalAnnuel, type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) { create(:market_attribute, input_type: :capacite_economique_financiere_chiffre_affaires_global_annuel) }

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
          'year_1' => {
            'turnover' => 500_000,
            'market_percentage' => 75,
            'fiscal_year_end' => '2023-12-31'
          },
          'year_2' => {
            'turnover' => 450_000,
            'market_percentage' => 80,
            'fiscal_year_end' => '2022-12-31'
          },
          'year_3' => {
            'turnover' => 400_000,
            'market_percentage' => 70,
            'fiscal_year_end' => '2021-12-31'
          }
        }
      end

      it { is_expected.to be_valid }
    end

    context 'with missing required year' do
      let(:value) do
        {
          'year_1' => {
            'turnover' => 500_000,
            'market_percentage' => 75,
            'fiscal_year_end' => '2023-12-31'
          },
          'year_2' => {
            'turnover' => 450_000,
            'market_percentage' => 80,
            'fiscal_year_end' => '2022-12-31'
          }
        }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:year_3]).to be_present
      end
    end

    context 'with invalid year data structure' do
      let(:value) do
        {
          'year_1' => 'not a hash',
          'year_2' => {
            'turnover' => 450_000,
            'market_percentage' => 80,
            'fiscal_year_end' => '2022-12-31'
          },
          'year_3' => {
            'turnover' => 400_000,
            'market_percentage' => 70,
            'fiscal_year_end' => '2021-12-31'
          }
        }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1 must be a hash')
      end
    end
  end

  describe 'turnover validation' do
    let(:base_value) do
      {
        'year_1' => {
          'turnover' => 500_000,
          'market_percentage' => 75,
          'fiscal_year_end' => '2023-12-31'
        },
        'year_2' => {
          'turnover' => 450_000,
          'market_percentage' => 80,
          'fiscal_year_end' => '2022-12-31'
        },
        'year_3' => {
          'turnover' => 400_000,
          'market_percentage' => 70,
          'fiscal_year_end' => '2021-12-31'
        }
      }
    end

    context 'with missing turnover' do
      let(:value) do
        base_value.tap { |v| v['year_1'].delete('turnover') }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1.turnover is required')
      end
    end

    context 'with negative turnover' do
      let(:value) do
        base_value.tap { |v| v['year_1']['turnover'] = -1000 }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1.turnover must be a positive integer')
      end
    end

    context 'with non-integer turnover' do
      let(:value) do
        base_value.tap { |v| v['year_1']['turnover'] = 'not_a_number' }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1.turnover must be a positive integer')
      end
    end

    context 'with zero turnover' do
      let(:value) do
        base_value.tap { |v| v['year_1']['turnover'] = 0 }
      end

      it { is_expected.to be_valid }
    end
  end

  describe 'percentage validation' do
    let(:base_value) do
      {
        'year_1' => {
          'turnover' => 500_000,
          'market_percentage' => 75,
          'fiscal_year_end' => '2023-12-31'
        },
        'year_2' => {
          'turnover' => 450_000,
          'market_percentage' => 80,
          'fiscal_year_end' => '2022-12-31'
        },
        'year_3' => {
          'turnover' => 400_000,
          'market_percentage' => 70,
          'fiscal_year_end' => '2021-12-31'
        }
      }
    end

    context 'with missing percentage' do
      let(:value) do
        base_value.tap { |v| v['year_1'].delete('market_percentage') }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1.market_percentage is required')
      end
    end

    context 'with percentage over 100' do
      let(:value) do
        base_value.tap { |v| v['year_1']['market_percentage'] = 101 }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1.market_percentage must be between 0 and 100')
      end
    end

    context 'with negative percentage' do
      let(:value) do
        base_value.tap { |v| v['year_1']['market_percentage'] = -1 }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1.market_percentage must be between 0 and 100')
      end
    end

    context 'with non-integer percentage' do
      let(:value) do
        base_value.tap { |v| v['year_1']['market_percentage'] = 'invalid' }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1.market_percentage must be between 0 and 100')
      end
    end

    context 'with valid boundary percentages' do
      let(:value) do
        {
          'year_1' => {
            'turnover' => 500_000,
            'market_percentage' => 0,
            'fiscal_year_end' => '2023-12-31'
          },
          'year_2' => {
            'turnover' => 450_000,
            'market_percentage' => 100,
            'fiscal_year_end' => '2022-12-31'
          },
          'year_3' => {
            'turnover' => 400_000,
            'market_percentage' => 50,
            'fiscal_year_end' => '2021-12-31'
          }
        }
      end

      it { is_expected.to be_valid }
    end
  end

  describe 'fiscal year end date validation' do
    let(:base_value) do
      {
        'year_1' => {
          'turnover' => 500_000,
          'market_percentage' => 75,
          'fiscal_year_end' => '2023-12-31'
        },
        'year_2' => {
          'turnover' => 450_000,
          'market_percentage' => 80,
          'fiscal_year_end' => '2022-12-31'
        },
        'year_3' => {
          'turnover' => 400_000,
          'market_percentage' => 70,
          'fiscal_year_end' => '2021-12-31'
        }
      }
    end

    context 'with missing fiscal year end' do
      let(:value) do
        base_value.tap { |v| v['year_1'].delete('fiscal_year_end') }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1.fiscal_year_end is required')
      end
    end

    context 'with invalid date format' do
      let(:value) do
        base_value.tap { |v| v['year_1']['fiscal_year_end'] = '31/12/2023' }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1.fiscal_year_end must be in YYYY-MM-DD format')
      end
    end

    context 'with invalid date' do
      let(:value) do
        base_value.tap { |v| v['year_1']['fiscal_year_end'] = '2023-02-30' }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1.fiscal_year_end is not a valid date')
      end
    end

    context 'with non-string date' do
      let(:value) do
        base_value.tap { |v| v['year_1']['fiscal_year_end'] = 20_231_231 }
      end

      it 'is invalid' do
        expect(response).not_to be_valid
        expect(response.errors[:value]).to include('year_1.fiscal_year_end must be in YYYY-MM-DD format')
      end
    end
  end

  describe 'virtual attributes' do
    let(:value) do
      {
        'year_1' => {
          'turnover' => 500_000,
          'market_percentage' => 75,
          'fiscal_year_end' => '2023-12-31'
        },
        'year_2' => {
          'turnover' => 450_000,
          'market_percentage' => 80,
          'fiscal_year_end' => '2022-12-31'
        }
      }
    end

    it 'provides getter methods for all year/field combinations' do
      expect(response.year_1_turnover).to eq(500_000)
      expect(response.year_1_market_percentage).to eq(75)
      expect(response.year_1_fiscal_year_end).to eq('2023-12-31')

      expect(response.year_2_turnover).to eq(450_000)
      expect(response.year_2_market_percentage).to eq(80)
      expect(response.year_2_fiscal_year_end).to eq('2022-12-31')
    end

    it 'allows setting values through virtual attributes' do
      response.year_3_turnover = '600000'
      response.year_3_market_percentage = '90'
      response.year_3_fiscal_year_end = '2024-12-31'

      expect(response.value['year_3']['turnover']).to eq(600_000)
      expect(response.value['year_3']['market_percentage']).to eq(90)
      expect(response.value['year_3']['fiscal_year_end']).to eq('2024-12-31')
    end

    it 'converts string integers to integers for numeric fields' do
      response.year_1_turnover = '123456'
      response.year_1_market_percentage = '85'

      expect(response.value['year_1']['turnover']).to be_an(Integer)
      expect(response.value['year_1']['market_percentage']).to be_an(Integer)
      expect(response.value['year_1']['turnover']).to eq(123_456)
      expect(response.value['year_1']['market_percentage']).to eq(85)
    end
  end

  describe 'class methods' do
    describe '.json_schema_properties' do
      it 'returns the expected properties' do
        expect(described_class.json_schema_properties).to eq(%w[year_1 year_2 year_3])
      end
    end

    describe '.json_schema_required' do
      it 'returns all years as required' do
        expect(described_class.json_schema_required).to eq(%w[year_1 year_2 year_3])
      end
    end

    describe '.json_schema_error_field' do
      it 'returns :value as the error field' do
        expect(described_class.json_schema_error_field).to eq(:value)
      end
    end
  end
end
