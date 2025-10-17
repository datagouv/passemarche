# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Rne::BuildResource, type: :interactor do
  include ApiResponses::RneResponses

  let(:siren) { '418166096' }
  let(:response_body) { rne_extrait_success_response(siren:) }
  let(:response) { instance_double(Net::HTTPOK, body: response_body) }

  describe '.call' do
    subject { described_class.call(response:) }

    context 'when the response contains valid data for personne_morale' do
      it_behaves_like 'a successful resource builder'
      it_behaves_like 'resource field extraction', :first_name_last_name, 'SOPHIE MARTIN'
      it_behaves_like 'resource field extraction', :head_office_address, '50 AVENUE DES CHAMPS ÉLYSÉES, 75008 PARIS 8, FRANCE'
    end

    context 'with different director names' do
      context 'when director has different name' do
        let(:response_body) do
          rne_extrait_success_response(
            siren:,
            overrides: {
              data: {
                dirigeants_et_associes: [
                  {
                    qualite: 'Président',
                    nom: 'DUPONT',
                    prenom: 'JEAN',
                    date_naissance: '03-1980',
                    commune_residence: 'LYON'
                  }
                ]
              }
            }
          )
        end

        it_behaves_like 'resource field extraction', :first_name_last_name, 'JEAN DUPONT'
      end

      context 'when there are no directors' do
        let(:response_body) do
          rne_extrait_success_response(
            siren:,
            overrides: {
              data: {
                dirigeants_et_associes: []
              }
            }
          )
        end

        it_behaves_like 'resource field extraction', :first_name_last_name, nil
      end
    end

    context 'with different head office addresses' do
      context 'when address has complement' do
        let(:response_body) do
          rne_extrait_success_response(
            siren:,
            overrides: {
              data: {
                identite_entreprise: {
                  adresse_siege_social: {
                    voie: '12 RUE DU COMMERCE',
                    code_postal: '69001',
                    commune: 'LYON 1ER ARRONDISSEMENT',
                    pays: 'FRANCE',
                    complement: 'Bâtiment B'
                  }
                }
              }
            }
          )
        end

        it_behaves_like 'resource field extraction', :head_office_address, '12 RUE DU COMMERCE, Bâtiment B, 69001 LYON 1ER ARRONDISSEMENT, FRANCE'
      end

      context 'when address has no complement' do
        let(:response_body) do
          rne_extrait_success_response(
            siren:,
            overrides: {
              data: {
                identite_entreprise: {
                  adresse_siege_social: {
                    voie: '1 PLACE DE LA LIBERTÉ',
                    code_postal: '75001',
                    commune: 'PARIS 1ER',
                    pays: 'FRANCE',
                    complement: nil
                  }
                }
              }
            }
          )
        end

        it_behaves_like 'resource field extraction', :head_office_address, '1 PLACE DE LA LIBERTÉ, 75001 PARIS 1ER, FRANCE'
      end
    end

    context 'for entrepreneur individuel (personne_physique)' do
      let(:siren) { '389839937' }
      let(:response_body) { rne_extrait_entrepreneur_individuel_response(siren:) }

      it_behaves_like 'a successful resource builder'

      it 'extracts first_name_last_name as nil (no directors for entrepreneur individuel)' do
        result = subject
        expect(result.bundled_data.data.first_name_last_name).to be_nil
      end

      it_behaves_like 'resource field extraction', :head_office_address, '12 RUE DU COMMERCE, Appartement 3, 69001 LYON 1ER ARRONDISSEMENT, FRANCE'
    end

    context 'when the response contains invalid JSON' do
      let(:response) { instance_double(Net::HTTPOK, body: rne_invalid_json_response) }

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
      let(:response) { instance_double(Net::HTTPOK, body: rne_empty_response) }

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
      let(:response) { instance_double(Net::HTTPOK, body: rne_response_without_data_key) }

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
