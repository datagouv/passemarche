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
      it_behaves_like 'resource field extraction', :main_activity, 'Conseil en systèmes et logiciels informatiques'
      it_behaves_like 'resource field extraction', :social_reason, 'OCTO TECHNOLOGY'
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

    context 'with different main_activity values' do
      context 'when main_activity has a different label' do
        let(:response_body) do
          insee_etablissement_success_response(
            siret:,
            overrides: {
              data: {
                activite_principale: {
                  code: '4711F',
                  libelle: 'Hypermarchés',
                  nomenclature: 'NAFRev2'
                }
              }
            }
          )
        end

        it_behaves_like 'resource field extraction', :main_activity, 'Hypermarchés'
      end

      context 'when main_activity is null' do
        let(:response_body) do
          insee_etablissement_success_response(
            siret:,
            overrides: {
              data: {
                activite_principale: nil
              }
            }
          )
        end

        it_behaves_like 'resource field extraction', :main_activity, nil
      end
    end

    context 'with different social_reason values' do
      context 'when social_reason has a different value' do
        let(:response_body) do
          insee_etablissement_success_response(
            siret:,
            overrides: {
              data: {
                unite_legale: {
                  personne_morale_attributs: {
                    raison_sociale: 'EXEMPLE SAS'
                  }
                }
              }
            }
          )
        end

        it_behaves_like 'resource field extraction', :social_reason, 'EXEMPLE SAS'
      end

      context 'when social_reason is null' do
        let(:response_body) do
          insee_etablissement_success_response(
            siret:,
            overrides: {
              data: {
                unite_legale: {
                  personne_morale_attributs: {
                    raison_sociale: nil
                  }
                }
              }
            }
          )
        end

        it_behaves_like 'resource field extraction', :social_reason, nil
      end
    end

    context 'with ESS (Economie Sociale et Solidaire) values' do
      context 'when economie_sociale_solidaire is true' do
        let(:response_body) do
          insee_etablissement_success_response(
            siret:,
            overrides: {
              data: {
                unite_legale: {
                  economie_sociale_solidaire: true
                }
              }
            }
          )
        end

        it 'returns ESS as a radio_with_file_and_text hash with yes choice' do
          result = subject
          expect(result.bundled_data.data.ess).to eq(
            { 'radio_choice' => 'yes', 'text' => I18n.t('api.insee.ess.is_ess') }
          )
        end
      end

      context 'when economie_sociale_solidaire is false' do
        let(:response_body) do
          insee_etablissement_success_response(
            siret:,
            overrides: {
              data: {
                unite_legale: {
                  economie_sociale_solidaire: false
                }
              }
            }
          )
        end

        it 'returns ESS as a radio_with_file_and_text hash with no choice' do
          result = subject
          expect(result.bundled_data.data.ess).to eq({ 'radio_choice' => 'no' })
        end
      end

      context 'when economie_sociale_solidaire is null' do
        let(:response_body) do
          insee_etablissement_success_response(
            siret:,
            overrides: {
              data: {
                unite_legale: {
                  economie_sociale_solidaire: nil
                }
              }
            }
          )
        end

        it 'returns nil for ESS to allow manual input' do
          result = subject
          expect(result.bundled_data.data.ess).to be_nil
        end
      end

      context 'when economie_sociale_solidaire is not present in response' do
        it 'returns nil for ESS' do
          result = subject
          expect(result.bundled_data.data.ess).to be_nil
        end
      end
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
