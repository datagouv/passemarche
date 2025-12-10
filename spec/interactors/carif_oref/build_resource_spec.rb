# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CarifOref::BuildResource, type: :interactor do
  include ApiResponses::CarifOrefResponses

  let(:successful_response_body) { carif_oref_success_response }

  let(:response) do
    instance_double(
      Net::HTTPSuccess,
      body: successful_response_body,
      code: '200',
      message: 'OK'
    )
  end

  describe '.call' do
    subject { described_class.call(response:) }

    context 'with valid JSON response containing both certifications' do
      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates bundled_data with Resource object' do
        result = subject
        expect(result.bundled_data).to be_a(BundledData)
        expect(result.bundled_data.data).to be_a(Resource)
      end

      it 'extracts qualiopi data' do
        result = subject
        qualiopi = result.bundled_data.data.qualiopi

        expect(qualiopi['numero_de_declaration']).to eq('11910843391')
        expect(qualiopi['actif']).to be true
        expect(qualiopi['date_derniere_declaration']).to eq('2021-01-30')
      end

      it 'extracts certification_qualiopi flags' do
        result = subject
        certification = result.bundled_data.data.qualiopi['certification_qualiopi']

        expect(certification['action_formation']).to be true
        expect(certification['bilan_competences']).to be true
        expect(certification['validation_acquis_experience']).to be false
        expect(certification['apprentissage']).to be true
        expect(certification['obtention_via_unite_legale']).to be true
      end

      it 'extracts specialites as array with code and libelle' do
        result = subject
        specialites = result.bundled_data.data.qualiopi['specialites']

        expect(specialites).to be_an(Array)
        expect(specialites.length).to eq(3)
        expect(specialites.first['code']).to eq('313')
        expect(specialites.first['libelle']).to eq('Finances, banque, assurances')
      end

      it 'extracts france_competence habilitations' do
        result = subject
        france_competence = result.bundled_data.data.france_competence

        expect(france_competence['habilitations']).to be_an(Array)
        expect(france_competence['habilitations'].length).to eq(2)
      end

      it 'extracts all habilitation details' do
        result = subject
        habilitation = result.bundled_data.data.france_competence['habilitations'].first

        expect(habilitation['code']).to eq('RNCP10013')
        expect(habilitation['actif']).to be true
        expect(habilitation['date_actif']).to eq('2020-01-30')
        expect(habilitation['date_fin_enregistrement']).to eq('2030-01-30')
        expect(habilitation['habilitation_pour_former']).to be true
        expect(habilitation['habilitation_pour_organiser_l_evaluation']).to be true
        expect(habilitation['sirets_organismes_certificateurs']).to eq(['12345678901234'])
      end
    end

    context 'with qualiopi only response' do
      let(:successful_response_body) { carif_oref_qualiopi_only_response }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'extracts qualiopi data' do
        result = subject
        expect(result.bundled_data.data.qualiopi).not_to be_nil
        expect(result.bundled_data.data.qualiopi['numero_de_declaration']).to eq('11910843391')
      end

      it 'returns nil for france_competence' do
        result = subject
        expect(result.bundled_data.data.france_competence).to be_nil
      end
    end

    context 'with france competences only response' do
      let(:successful_response_body) { carif_oref_france_competences_only_response }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'returns nil for qualiopi' do
        result = subject
        expect(result.bundled_data.data.qualiopi).to be_nil
      end

      it 'extracts france_competence data' do
        result = subject
        expect(result.bundled_data.data.france_competence).not_to be_nil
        expect(result.bundled_data.data.france_competence['habilitations'].length).to eq(1)
      end
    end

    context 'with empty response' do
      let(:successful_response_body) { carif_oref_empty_response }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'returns nil for qualiopi' do
        result = subject
        expect(result.bundled_data.data.qualiopi).to be_nil
      end

      it 'returns nil for france_competence' do
        result = subject
        expect(result.bundled_data.data.france_competence).to be_nil
      end
    end

    context 'when response body is invalid JSON' do
      let(:response) do
        instance_double(
          Net::HTTPSuccess,
          body: carif_oref_invalid_json_response,
          code: '200',
          message: 'OK'
        )
      end

      it 'fails with invalid JSON error' do
        result = subject
        expect(result).to be_failure
        expect(result.error).to eq('Invalid JSON response')
      end
    end

    context 'when data key is missing' do
      let(:successful_response_body) { { links: {}, meta: {} }.to_json }

      it 'fails with invalid JSON error' do
        result = subject
        expect(result).to be_failure
        expect(result.error).to eq('Invalid JSON response')
      end
    end
  end
end
