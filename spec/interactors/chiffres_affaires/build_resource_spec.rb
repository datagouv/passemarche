require 'rails_helper'

RSpec.describe Dgfip::ChiffresAffaires::BuildResource, type: :interactor do
  include ApiResponses::ChiffresAffairesResponses

  let(:siret) { '41816609600069' }
  let(:response_body) { chiffres_affaires_success_response }
  let(:response) { instance_double(Net::HTTPOK, body: response_body) }

  describe '.call' do
    subject { described_class.call(response:) }

    context 'when the response contains valid chiffres d\'affaires data' do
      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'extracts data in year_1/year_2/year_3 format' do
        result = subject
        data = result.bundled_data.data

        expect(data.chiffres_affaires_data).to be_present
        parsed_data = JSON.parse(data.chiffres_affaires_data)

        expect(parsed_data).to have_key('year_1')
        expect(parsed_data).to have_key('year_2')
        expect(parsed_data).to have_key('year_3')

        # Year 1 (2023)
        expect(parsed_data['year_1']['turnover']).to eq(500_000)
        expect(parsed_data['year_1']['market_percentage']).to be_nil
        expect(parsed_data['year_1']['fiscal_year_end']).to eq('2023-12-31')

        # Year 2 (2022)
        expect(parsed_data['year_2']['turnover']).to eq(450_000)
        expect(parsed_data['year_2']['market_percentage']).to be_nil
        expect(parsed_data['year_2']['fiscal_year_end']).to eq('2022-12-31')

        # Year 3 (2021)
        expect(parsed_data['year_3']['turnover']).to eq(400_000)
        expect(parsed_data['year_3']['market_percentage']).to be_nil
        expect(parsed_data['year_3']['fiscal_year_end']).to eq('2021-12-31')
      end

      it 'includes fiscal year end dates' do
        result = subject
        data = result.bundled_data.data
        parsed_data = JSON.parse(data.chiffres_affaires_data)

        expect(parsed_data['year_1']['fiscal_year_end']).to eq('2023-12-31')
        expect(parsed_data['year_2']['fiscal_year_end']).to eq('2022-12-31')
        expect(parsed_data['year_3']['fiscal_year_end']).to eq('2021-12-31')
      end
    end

    context 'when the response contains empty chiffres d\'affaires' do
      let(:response_body) { chiffres_affaires_empty_response }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'returns empty data structure' do
        result = subject
        data = result.bundled_data.data
        parsed_data = JSON.parse(data.chiffres_affaires_data)

        expect(parsed_data['year_1']['turnover']).to be_nil
        expect(parsed_data['year_1']['market_percentage']).to be_nil
        expect(parsed_data['year_1']['fiscal_year_end']).to be_nil

        expect(parsed_data['year_2']['turnover']).to be_nil
        expect(parsed_data['year_2']['market_percentage']).to be_nil
        expect(parsed_data['year_2']['fiscal_year_end']).to be_nil

        expect(parsed_data['year_3']['turnover']).to be_nil
        expect(parsed_data['year_3']['market_percentage']).to be_nil
        expect(parsed_data['year_3']['fiscal_year_end']).to be_nil
      end
    end

    context 'when the response contains invalid JSON' do
      let(:response) { instance_double(Net::HTTPOK, body: chiffres_affaires_invalid_json_response) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'sets an error message about invalid JSON' do
        result = subject
        expect(result.error).to eq('Invalid JSON response')
      end
    end

    context 'when response has fewer than 3 years of data' do
      let(:response_body) do
        chiffres_affaires_success_response(
          overrides: {
            data: [
              {
                data: {
                  chiffre_affaires: 450_000,
                  date_fin_exercice: '2023-12-31'
                }
              }
            ]
          }
        )
      end

      it 'returns only available years' do
        result = subject
        data = result.bundled_data.data
        parsed_data = JSON.parse(data.chiffres_affaires_data)

        expect(parsed_data['year_1']['turnover']).to eq(450_000)
        expect(parsed_data['year_1']['market_percentage']).to be_nil
        expect(parsed_data['year_1']['fiscal_year_end']).to eq('2023-12-31')

        # Year 2 and 3 should be nil as no data available
        expect(parsed_data['year_2']['turnover']).to be_nil
        expect(parsed_data['year_2']['market_percentage']).to be_nil
        expect(parsed_data['year_2']['fiscal_year_end']).to be_nil

        expect(parsed_data['year_3']['turnover']).to be_nil
        expect(parsed_data['year_3']['market_percentage']).to be_nil
        expect(parsed_data['year_3']['fiscal_year_end']).to be_nil
      end
    end
  end
end
