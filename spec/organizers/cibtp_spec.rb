# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cibtp, type: :organizer do
  let(:siret) { '41816609600069' }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }
  let(:token) { 'test_bearer_token_123' }
  let(:endpoint_url) { "#{base_url}v3/cibtp/etablissements/#{siret}/attestation_cotisations_conges_payes_chomage_intemperies" }
  let(:document_url) { "https://storage.entreprise.api.gouv.fr/siade/1569139162-#{siret}-certificat_cibtp.pdf" }
  let(:document_body) { '%PDF-1.4 fake pdf content with enough bytes to pass minimum size validation requiring at least 100 bytes total' }
  let(:query_params) do
    {
      'context' => 'Candidature marché public',
      'recipient' => '13002526500013',
      'object' => 'Réponse appel offre'
    }
  end

  let(:api_response_body) do
    {
      data: {
        document_url:,
        expires_in: 600
      },
      links: {},
      meta: {}
    }.to_json
  end

  before do
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :base_url).and_return(base_url)
    allow(Rails.application.credentials).to receive_message_chain(:api_entreprise, :token).and_return(token)
  end

  describe '.call' do
    subject { described_class.call(params: { siret: }) }

    context 'when full pipeline succeeds' do
      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including(query_params))
          .to_return(status: 200, body: api_response_body, headers: { 'Content-Type' => 'application/json' })

        stub_request(:get, document_url)
          .to_return(
            status: 200,
            body: document_body,
            headers: {
              'Content-Type' => 'application/pdf',
              'Content-Disposition' => "attachment; filename=\"attestation_cibtp_#{siret}.pdf\""
            }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'stores downloaded document in context.bundled_data.data.cibtp_document' do
        result = subject
        document = result.bundled_data.data.cibtp_document

        expect(document).to be_a(Hash)
        expect(document[:io]).to be_a(StringIO)
        expect(document[:filename]).to eq("attestation_cibtp_#{siret}.pdf")
        expect(document[:content_type]).to eq('application/pdf')
      end

      it 'includes correct metadata' do
        result = subject
        metadata = result.bundled_data.data.cibtp_document[:metadata]

        expect(metadata).to include(
          source: 'api_cibtp',
          api_name: 'cibtp'
        )
      end

      it 'sets api_name in context' do
        result = subject
        expect(result.api_name).to eq('cibtp')
      end
    end

    context 'when API request fails' do
      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including(query_params))
          .to_return(status: 404, body: { errors: [{ title: 'Not found' }] }.to_json)
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        expect(subject.error).to be_present
      end
    end

    context 'when document download fails' do
      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including(query_params))
          .to_return(status: 200, body: api_response_body)

        stub_request(:get, document_url)
          .to_return(status: 404, body: 'Not Found')
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error about failed download' do
        expect(subject.error).to include('Failed to download')
      end
    end

    context 'when SIRET is passed through pipeline' do
      before do
        stub_request(:get, endpoint_url)
          .with(query: hash_including(query_params))
          .to_return(status: 200, body: api_response_body)

        stub_request(:get, document_url)
          .to_return(
            status: 200,
            body: document_body,
            headers: {
              'Content-Type' => 'application/pdf',
              'Content-Disposition' => "attachment; filename=\"attestation_cibtp_#{siret}.pdf\""
            }
          )
      end

      it 'uses SIRET in URL' do
        subject
        expect(a_request(:get, endpoint_url).with(query: hash_including(query_params))).to have_been_made.once
      end

      it 'uses SIRET in filename' do
        result = subject
        expect(result.bundled_data.data.cibtp_document[:filename]).to include(siret)
      end
    end
  end
end
