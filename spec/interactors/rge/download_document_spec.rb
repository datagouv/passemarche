# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Rge::DownloadDocument, type: :interactor do
  let(:siret) { '78824266700020' }
  let(:document_body_1) { '%PDF-1.4 fake pdf content for certificate 1 with enough bytes to pass minimum size validation requiring 100 bytes' }
  let(:document_body_2) { '%PDF-1.5 fake pdf content for certificate 2 with enough bytes to pass minimum size validation requiring 100 bytes' }

  let(:cert1_url) { 'https://example.com/cert1.pdf' }
  let(:cert2_url) { 'https://example.com/cert2.pdf' }

  let(:certificates) do
    [
      {
        url: cert1_url,
        nom_certificat: 'Qualisol CESI',
        domaine: 'Fenêtres, volets',
        organisme: 'qualibat',
        date_expiration: '2025-08-01'
      },
      {
        url: cert2_url,
        nom_certificat: 'QualiPV Elec',
        domaine: 'Installation électrique',
        organisme: 'qualit_enr',
        date_expiration: '2026-01-15'
      }
    ]
  end

  let(:resource) { Resource.new(documents: certificates) }
  let(:bundled_data) { BundledData.new(data: resource) }
  let(:token) { 'test-token-12345' }

  before do
    allow(Rails.application.credentials).to receive(:api_entreprise).and_return(
      OpenStruct.new(token:)
    )
  end

  describe '.call' do
    subject { described_class.call(bundled_data:, params: { siret: }, api_name: 'rge') }

    context 'when all documents are successfully downloaded' do
      before do
        stub_request(:get, cert1_url)
          .to_return(
            status: 200,
            body: document_body_1,
            headers: { 'Content-Type' => 'application/pdf' }
          )

        stub_request(:get, cert2_url)
          .to_return(
            status: 200,
            body: document_body_2,
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'replaces documents array with downloaded document hashes' do
        result = subject
        documents = result.bundled_data.data.documents

        expect(documents).to be_an(Array)
        expect(documents.size).to eq(2)
        expect(documents.all?(Hash)).to be true
        expect(documents.all? { |doc| doc[:io].is_a?(StringIO) }).to be true
      end

      it 'generates unique filenames based on certificate names' do
        result = subject
        documents = result.bundled_data.data.documents

        expect(documents[0][:filename]).to eq("certificat_rge_#{siret}_qualisol-cesi.pdf")
        expect(documents[1][:filename]).to eq("certificat_rge_#{siret}_qualipv-elec.pdf")
      end

      it 'includes metadata for each document' do
        result = subject
        documents = result.bundled_data.data.documents

        documents.each do |doc|
          metadata = doc[:metadata]
          expect(metadata).to include(
            source: 'api_rge',
            api_name: 'rge',
            downloaded_at: be_a(String)
          )
        end
      end

      it 'includes certificate-specific metadata' do
        result = subject
        documents = result.bundled_data.data.documents

        expect(documents[0][:metadata][:nom_certificat]).to eq('Qualisol CESI')
        expect(documents[0][:metadata][:organisme]).to eq('qualibat')
        expect(documents[1][:metadata][:nom_certificat]).to eq('QualiPV Elec')
        expect(documents[1][:metadata][:organisme]).to eq('qualit_enr')
      end
    end

    context 'when some documents fail to download (partial failure)' do
      before do
        stub_request(:get, cert1_url)
          .to_return(
            status: 200,
            body: document_body_1,
            headers: { 'Content-Type' => 'application/pdf' }
          )

        stub_request(:get, cert2_url)
          .to_return(status: 404, body: 'Not Found')
      end

      it 'succeeds (best-effort approach)' do
        expect(subject).to be_success
      end

      it 'includes only successfully downloaded documents' do
        result = subject
        documents = result.bundled_data.data.documents

        expect(documents.size).to eq(1)
        expect(documents[0][:filename]).to eq("certificat_rge_#{siret}_qualisol-cesi.pdf")
      end
    end

    context 'when all documents fail to download' do
      before do
        stub_request(:get, cert1_url)
          .to_return(status: 404, body: 'Not Found')

        stub_request(:get, cert2_url)
          .to_return(status: 500, body: 'Server Error')
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        expect(subject.error).to eq('Failed to download any RGE certificates')
      end
    end

    context 'when documents array is empty' do
      let(:resource) { Resource.new(documents: []) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'keeps empty documents array' do
        result = subject
        expect(result.bundled_data.data.documents).to eq([])
      end
    end

    context 'when documents key is missing' do
      let(:resource) { Resource.new }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message about missing documents' do
        expect(subject.error).to eq('Missing or invalid documents array in response')
      end
    end

    context 'when bundled_data is missing' do
      subject { described_class.call(params: { siret: }, api_name: 'rge') }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message about missing bundled_data' do
        expect(subject.error).to eq('Missing bundled_data')
      end
    end

    context 'when a document has missing nom_certificat' do
      let(:certificates) do
        [
          {
            url: cert1_url,
            nom_certificat: nil,
            domaine: 'Test domaine',
            organisme: 'test_org',
            date_expiration: '2025-01-01'
          }
        ]
      end

      before do
        stub_request(:get, cert1_url)
          .to_return(
            status: 200,
            body: document_body_1,
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'generates filename with index fallback' do
        result = subject
        documents = result.bundled_data.data.documents

        expect(documents[0][:filename]).to eq("certificat_rge_#{siret}_1.pdf")
      end
    end

    context 'when one downloaded file is not a valid PDF' do
      before do
        stub_request(:get, cert1_url)
          .to_return(
            status: 200,
            body: 'Not a PDF - just HTML error page content that is long enough to pass minimum size validation requiring 100 bytes',
            headers: { 'Content-Type' => 'application/pdf' }
          )

        stub_request(:get, cert2_url)
          .to_return(
            status: 200,
            body: document_body_2,
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'succeeds with valid documents only' do
        expect(subject).to be_success
      end

      it 'includes only valid documents' do
        result = subject
        documents = result.bundled_data.data.documents

        expect(documents.size).to eq(1)
        expect(documents[0][:filename]).to eq("certificat_rge_#{siret}_qualipv-elec.pdf")
      end
    end

    context 'when all downloaded files are invalid' do
      before do
        stub_request(:get, cert1_url)
          .to_return(
            status: 200,
            body: 'Not a PDF - just HTML error page content that is long enough to pass minimum size validation requiring 100 bytes',
            headers: { 'Content-Type' => 'application/pdf' }
          )

        stub_request(:get, cert2_url)
          .to_return(
            status: 200,
            body: 'Also not a PDF - HTML content that is long enough to pass the minimum size check requiring over 100 bytes',
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        expect(subject.error).to eq('Failed to download any RGE certificates')
      end
    end

    context 'when HTTP request times out' do
      before do
        stub_request(:get, cert1_url)
          .to_timeout

        stub_request(:get, cert2_url)
          .to_return(
            status: 200,
            body: document_body_2,
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'succeeds (best-effort)' do
        expect(subject).to be_success
      end

      it 'skips timed-out documents and keeps successful ones' do
        result = subject
        documents = result.bundled_data.data.documents

        expect(documents.size).to eq(1)
        expect(documents[0][:filename]).to eq("certificat_rge_#{siret}_qualipv-elec.pdf")
      end
    end
  end
end
