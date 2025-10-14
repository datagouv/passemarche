# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Insee::BuildResource, type: :interactor do
  include ApiResponses::InseeResponses

  let(:siret) { '41816609600069' }
  let(:response_body) { insee_etablissement_success_response(siret:) }
  let(:response) { instance_double(Net::HTTPOK, body: response_body) }

  describe '.call' do
    subject { described_class.call(response:) }

    context 'when the response contains valid data' do
      it_behaves_like 'a successful resource builder'
      it_behaves_like 'resource field extraction', :siret, '41816609600069'
      it_behaves_like 'resource field extraction', :category, 'PME'
    end

    context 'with different category values' do
      context 'when category is GE (Grande Entreprise)' do
        let(:response_body) do
          insee_etablissement_success_response(
            siret:,
            overrides: {
              data: {
                unite_legale: {
                  categorie_entreprise: 'GE'
                }
              }
            }
          )
        end

        it_behaves_like 'resource field extraction', :category, 'GE'
      end

      context 'when category is ETI (Entreprise de Taille Intermédiaire)' do
        let(:response_body) do
          insee_etablissement_success_response(
            siret:,
            overrides: {
              data: {
                unite_legale: {
                  categorie_entreprise: 'ETI'
                }
              }
            }
          )
        end

        it_behaves_like 'resource field extraction', :category, 'ETI'
      end

      context 'when category is null' do
        let(:response_body) do
          insee_etablissement_success_response(
            siret:,
            overrides: {
              data: {
                unite_legale: {
                  categorie_entreprise: nil
                }
              }
            }
          )
        end

        it_behaves_like 'resource field extraction', :category, nil
      end
    end

    context 'with different SIRET values' do
      let(:siret) { '13002526500013' }

      it_behaves_like 'resource field extraction', :siret, '13002526500013'
    end

    context 'when the response contains invalid JSON' do
      let(:response) { instance_double(Net::HTTPOK, body: insee_invalid_json_response) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'sets an error message about invalid JSON' do
        result = subject
        expect(result.error).to eq('Invalid JSON response')
      end

      it 'does not create bundled_data' do
        result = subject
        expect(result.bundled_data).to be_nil
      end
    end

    context 'when the response body is empty' do
      let(:response) { instance_double(Net::HTTPOK, body: insee_empty_response) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'sets an error message about invalid JSON' do
        result = subject
        expect(result.error).to eq('Invalid JSON response')
      end

      it 'does not create bundled_data' do
        result = subject
        expect(result.bundled_data).to be_nil
      end
    end

    context 'when the response is valid JSON but missing data key' do
      let(:response) { instance_double(Net::HTTPOK, body: insee_response_without_data_key) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'sets an error message about invalid JSON' do
        result = subject
        expect(result.error).to eq('Invalid JSON response')
      end

      it 'does not create bundled_data' do
        result = subject
        expect(result.bundled_data).to be_nil
      end
    end
  end
end
