# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Insee::MakeRequest, type: :interactor do
  let(:siret) { '41816609600069' }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }
  let(:token) { 'test_bearer_token_123' }
  let(:endpoint_url) { "#{base_url}v3/insee/sirene/etablissements/#{siret}" }

  # Mock API response based on swagger specification
  let(:successful_response_body) do
    {
      data: {
        siret: '41816609600069',
        siege_social: true,
        etat_administratif: 'A',
        date_fermeture: nil,
        activite_principale: {
          code: '6202A',
          libelle: 'Conseil en systèmes et logiciels informatiques',
          nomenclature: 'NAFRev2'
        },
        tranche_effectif_salarie: {
          code: '21',
          intitule: '50 à 99 salariés',
          date_reference: '2022',
          de: 50,
          a: 99
        },
        status_diffusion: 'diffusible',
        diffusable_commercialement: true,
        enseigne: 'OCTO TECHNOLOGY',
        unite_legale: {
          siren: '418166096',
          rna: nil,
          siret_siege_social: '41816609600069',
          type: 'personne_morale',
          personne_morale_attributs: {
            raison_sociale: 'OCTO TECHNOLOGY',
            sigle: 'OCTO'
          },
          personne_physique_attributs: {
            pseudonyme: nil,
            prenom_usuel: nil,
            prenom_1: nil,
            prenom_2: nil,
            prenom_3: nil,
            prenom_4: nil,
            nom_usage: nil,
            nom_naissance: nil,
            sexe: nil
          },
          categorie_entreprise: 'PME',
          status_diffusion: 'diffusible'
        }
      },
      meta: {
        date_derniere_mise_a_jour: 1_704_067_200
      },
      links: {}
    }.to_json
  end

  before do
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :base_url).and_return(base_url)
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :token).and_return(token)
  end

  describe '.call' do
    subject { described_class.call(params: { siret: }) }

    context 'when the API request is successful (HTTP 200)' do
      before do
        stub_request(:get, endpoint_url)
          .with(
            headers: {
              'Authorization' => "Bearer #{token}",
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 200,
            body: successful_response_body,
            headers: {
              'Content-Type' => 'application/json',
              'RateLimit-Limit' => '50',
              'RateLimit-Remaining' => '47',
              'RateLimit-Reset' => '1637223155'
            }
          )
      end

      it_behaves_like 'a successful API request'
    end

    it_behaves_like 'API request error handling'

    context 'with different SIRET values' do
      let(:siret) { '13002526500013' }
      let(:endpoint_url) { "#{base_url}v3/insee/sirene/etablissements/#{siret}" }

      before do
        stub_request(:get, endpoint_url)
          .to_return(status: 200, body: successful_response_body)
      end

      it 'builds the correct endpoint URL' do
        subject
        expect(a_request(:get, endpoint_url)).to have_been_made.once
      end
    end
  end
end
