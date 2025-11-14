# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CotisationRetraite, type: :organizer do
  let(:siret) { '41816609600069' }
  let(:siren) { siret[0..8] }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }
  let(:token) { 'test_bearer_token_123' }

  let(:cibtp_endpoint) { "#{base_url}v3/cibtp/etablissements/#{siret}/attestation_cotisations_conges_payes_chomage_intemperies" }
  let(:cnetp_endpoint) { "#{base_url}v3/cnetp/unites_legales/#{siren}/attestation_cotisations_conges_payes_chomage_intemperies" }

  let(:cibtp_doc_url) { "https://storage.entreprise.api.gouv.fr/siade/1569139162-#{siret}-certificat_cibtp.pdf" }
  let(:cnetp_doc_url) { "https://storage.entreprise.api.gouv.fr/siade/1569139162-#{siren}-certificat_cnetp.pdf" }

  let(:document_body) { '%PDF-1.4 fake pdf content with enough bytes to pass minimum size validation requiring at least 100 bytes total' }

  let(:query_params) do
    {
      'context' => 'Candidature marché public',
      'recipient' => '13002526500013',
      'object' => 'Réponse appel offre'
    }
  end

  let(:cibtp_response) do
    {
      data: { document_url: cibtp_doc_url, expires_in: 600 },
      links: {},
      meta: {}
    }.to_json
  end

  let(:cnetp_response) do
    {
      data: { document_url: cnetp_doc_url, expires_in: 7_889_238 },
      links: {},
      meta: {}
    }.to_json
  end

  before do
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :base_url).and_return(base_url)
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :token).and_return(token)
  end

  describe '.call' do
    subject { described_class.call(params: { siret:, siren: }) }

    context 'when both CIBTP and CNETP succeed' do
      before do
        # CIBTP API success
        stub_request(:get, cibtp_endpoint)
          .with(query: hash_including(query_params))
          .to_return(status: 200, body: cibtp_response, headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, cibtp_doc_url)
          .to_return(
            status: 200,
            body: document_body,
            headers: {
              'Content-Type' => 'application/pdf',
              'Content-Disposition' => "attachment; filename=\"attestation_cibtp_#{siret}.pdf\""
            }
          )

        # CNETP API success
        stub_request(:get, cnetp_endpoint)
          .with(query: hash_including(query_params))
          .to_return(status: 200, body: cnetp_response, headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, cnetp_doc_url)
          .to_return(
            status: 200,
            body: document_body,
            headers: {
              'Content-Type' => 'application/pdf',
              'Content-Disposition' => "attachment; filename=\"attestation_cnetp_#{siren}.pdf\""
            }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'returns 2 documents in merged resource' do
        result = subject
        documents = result.bundled_data.data.documents

        expect(documents).to be_an(Array)
        expect(documents.length).to eq(2)
      end

      it 'sets status to success_both' do
        result = subject
        expect(result.bundled_data.context[:status]).to eq('success_both')
      end

      it 'sets api_name in context' do
        result = subject
        expect(result.api_name).to eq('cotisation_retraite')
      end
    end

    context 'when only CIBTP succeeds (CNETP fails)' do
      before do
        # CIBTP API success
        stub_request(:get, cibtp_endpoint)
          .with(query: hash_including(query_params))
          .to_return(status: 200, body: cibtp_response, headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, cibtp_doc_url)
          .to_return(
            status: 200,
            body: document_body,
            headers: {
              'Content-Type' => 'application/pdf',
              'Content-Disposition' => "attachment; filename=\"attestation_cibtp_#{siret}.pdf\""
            }
          )

        # CNETP API failure (404 - company not in CNETP)
        stub_request(:get, cnetp_endpoint)
          .with(query: hash_including(query_params))
          .to_return(status: 404, body: { errors: [{ title: 'Not found' }] }.to_json)
      end

      it 'succeeds (partial success is still success)' do
        expect(subject).to be_success
      end

      it 'returns 1 document (only CIBTP)' do
        result = subject
        documents = result.bundled_data.data.documents

        expect(documents.length).to eq(1)
        expect(documents.first[:filename]).to include('cibtp')
      end

      it 'sets status to success_partial' do
        result = subject
        expect(result.bundled_data.context[:status]).to eq('success_partial')
      end
    end

    context 'when only CNETP succeeds (CIBTP fails)' do
      before do
        # CIBTP API failure (404 - company not in CIBTP)
        stub_request(:get, cibtp_endpoint)
          .with(query: hash_including(query_params))
          .to_return(status: 404, body: { errors: [{ title: 'Not found' }] }.to_json)

        # CNETP API success
        stub_request(:get, cnetp_endpoint)
          .with(query: hash_including(query_params))
          .to_return(status: 200, body: cnetp_response, headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, cnetp_doc_url)
          .to_return(
            status: 200,
            body: document_body,
            headers: {
              'Content-Type' => 'application/pdf',
              'Content-Disposition' => "attachment; filename=\"attestation_cnetp_#{siren}.pdf\""
            }
          )
      end

      it 'succeeds (partial success is still success)' do
        expect(subject).to be_success
      end

      it 'returns 1 document (only CNETP)' do
        result = subject
        documents = result.bundled_data.data.documents

        expect(documents.length).to eq(1)
        expect(documents.first[:filename]).to include('cnetp')
      end

      it 'sets status to success_partial' do
        result = subject
        expect(result.bundled_data.context[:status]).to eq('success_partial')
      end
    end

    context 'when both CIBTP and CNETP fail' do
      before do
        # Both APIs fail
        stub_request(:get, cibtp_endpoint)
          .with(query: hash_including(query_params))
          .to_return(status: 404, body: { errors: [{ title: 'Not found' }] }.to_json)

        stub_request(:get, cnetp_endpoint)
          .with(query: hash_including(query_params))
          .to_return(status: 404, body: { errors: [{ title: 'Not found' }] }.to_json)
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error about both APIs failing' do
        expect(subject.error).to include('Both')
      end
    end
  end

  describe 'MapApiData integration' do
    let(:public_market) { create(:public_market, :completed) }
    let(:market_application) { create(:market_application, public_market:, siret:) }

    let!(:cotisation_retraite_attribute) do
      create(:market_attribute, api_name: 'cotisation_retraite', api_key: 'documents').tap do |attr|
        attr.public_markets << public_market
      end
    end

    let(:query_params_with_market) do
      {
        'context' => 'Candidature marché public',
        'recipient' => '13002526500013',
        'object' => "Réponse marché: #{public_market.name}"
      }
    end

    subject do
      described_class.call(
        params: { siret:, siren: },
        market_application:
      )
    end

    context 'when at least one API succeeds' do
      before do
        # CIBTP succeeds
        stub_request(:get, cibtp_endpoint)
          .with(query: hash_including(query_params_with_market))
          .to_return(status: 200, body: cibtp_response, headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, cibtp_doc_url)
          .to_return(
            status: 200,
            body: document_body,
            headers: {
              'Content-Type' => 'application/pdf',
              'Content-Disposition' => "attachment; filename=\"attestation_cibtp_#{siret}.pdf\""
            }
          )

        # CNETP fails
        stub_request(:get, cnetp_endpoint)
          .with(query: hash_including(query_params_with_market))
          .to_return(status: 404, body: { errors: [{ title: 'Not found' }] }.to_json)
      end

      it 'calls MapApiData and creates responses with source=auto' do
        expect do
          subject
        end.to change { market_application.market_attribute_responses.count }.by(1)

        response = market_application.market_attribute_responses
          .joins(:market_attribute)
          .find_by(market_attributes: { api_name: 'cotisation_retraite' })

        expect(response).to be_present
        expect(response.source).to eq('auto')
        expect(response.documents).to be_attached
      end

      it 'succeeds' do
        expect(subject).to be_success
      end
    end

    context 'when both APIs fail' do
      before do
        # Both APIs fail
        stub_request(:get, cibtp_endpoint)
          .with(query: hash_including(query_params_with_market))
          .to_return(status: 404, body: { errors: [{ title: 'Not found' }] }.to_json)

        stub_request(:get, cnetp_endpoint)
          .with(query: hash_including(query_params_with_market))
          .to_return(status: 404, body: { errors: [{ title: 'Not found' }] }.to_json)
      end

      it 'does not call MapApiData and does not create responses' do
        expect do
          subject
        end.not_to change { market_application.market_attribute_responses.count }
      end

      it 'fails' do
        expect(subject).to be_failure
      end
    end
  end
end
