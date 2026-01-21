# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActesBilans::DownloadDocument, type: :interactor do
  let(:siret) { '78824266700020' }
  let(:siren) { '788242667' }
  let(:document_url_1) { 'https://inpi.example.com/bilan-1.pdf' }
  let(:document_url_2) { 'https://inpi.example.com/bilan-2.pdf' }
  let(:document_url_3) { 'https://inpi.example.com/bilan-3.pdf' }
  let(:pdf_header) { '%PDF-'.dup.force_encoding('ASCII-8BIT') }
  let(:document_body_1) { (pdf_header.dup + ("\x00" * 200).force_encoding('ASCII-8BIT')) }
  let(:document_body_2) { (pdf_header.dup + ("\x00" * 250).force_encoding('ASCII-8BIT')) }
  let(:document_body_3) { (pdf_header.dup + ("\x00" * 300).force_encoding('ASCII-8BIT')) }
  let(:resource) { Resource.new(actes_et_bilans: [document_url_1, document_url_2, document_url_3]) }
  let(:bundled_data) { BundledData.new(data: resource) }
  let(:token) { 'test-token-12345' }

  before do
    allow(Rails.application.credentials).to receive(:api_entreprise).and_return(
      OpenStruct.new(token:)
    )
  end

  describe '.call' do
    subject { described_class.call(bundled_data:, params: { siret: }, api_name: 'actes_bilans') }

    context 'when multiple documents are successfully downloaded' do
      before do
        stub_request(:get, document_url_1)
          .to_return(
            status: 200,
            body: document_body_1,
            headers: { 'Content-Type' => 'application/pdf' }
          )

        stub_request(:get, document_url_2)
          .to_return(
            status: 200,
            body: document_body_2,
            headers: { 'Content-Type' => 'application/pdf' }
          )

        stub_request(:get, document_url_3)
          .to_return(
            status: 200,
            body: document_body_3,
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'replaces actes_et_bilans array with downloaded document hashes' do
        result = subject
        documents = result.bundled_data.data.actes_et_bilans

        expect(documents).to be_an(Array)
        expect(documents.size).to eq(3)

        documents.each do |document|
          expect(document).to be_a(Hash)
          expect(document[:io]).to be_a(StringIO)
          expect(document[:content_type]).to eq('application/pdf')
        end
      end

      it 'generates unique filenames with index' do
        result = subject
        documents = result.bundled_data.data.actes_et_bilans

        expect(documents[0][:filename]).to eq("bilan_#{siren}_1.pdf")
        expect(documents[1][:filename]).to eq("bilan_#{siren}_2.pdf")
        expect(documents[2][:filename]).to eq("bilan_#{siren}_3.pdf")
      end

      it 'includes metadata for each document' do
        result = subject
        documents = result.bundled_data.data.actes_et_bilans

        documents.each do |document|
          metadata = document[:metadata]
          expect(metadata).to include(
            source: 'api_actes_bilans',
            api_name: 'actes_bilans',
            downloaded_at: be_a(String)
          )
        end
      end
    end

    context 'when documents array is empty' do
      let(:resource) { Resource.new(actes_et_bilans: []) }

      it 'succeeds with empty array' do
        result = subject
        expect(result).to be_success
        expect(result.bundled_data.data.actes_et_bilans).to eq([])
      end
    end

    context 'when actes_et_bilans key is missing' do
      let(:resource) { Resource.new }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message about missing actes_et_bilans' do
        expect(subject.error).to eq('Missing actes_et_bilans in response')
      end
    end

    context 'when one document download fails' do
      before do
        stub_request(:get, document_url_1)
          .to_return(status: 404, body: 'Not Found')

        stub_request(:get, document_url_2)
          .to_return(
            status: 200,
            body: document_body_2,
            headers: { 'Content-Type' => 'application/pdf' }
          )

        stub_request(:get, document_url_3)
          .to_return(
            status: 200,
            body: document_body_3,
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'succeeds with partial results' do
        expect(subject).to be_success
      end

      it 'includes only successfully downloaded documents' do
        result = subject
        documents = result.bundled_data.data.actes_et_bilans

        expect(documents.size).to eq(2)
        expect(documents[0][:filename]).to eq("bilan_#{siren}_2.pdf")
        expect(documents[1][:filename]).to eq("bilan_#{siren}_3.pdf")
      end
    end

    context 'when all document downloads fail' do
      before do
        stub_request(:get, document_url_1)
          .to_return(status: 404, body: 'Not Found')

        stub_request(:get, document_url_2)
          .to_return(status: 500, body: 'Server Error')

        stub_request(:get, document_url_3)
          .to_return(status: 503, body: 'Service Unavailable')
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        expect(subject.error).to eq('Failed to download any documents')
      end
    end

    context 'when one downloaded file is not a valid PDF' do
      before do
        stub_request(:get, document_url_1)
          .to_return(
            status: 200,
            body: 'Not a PDF - just some HTML error page content that is long enough to pass size check requiring over 100 bytes',
            headers: { 'Content-Type' => 'application/pdf' }
          )

        stub_request(:get, document_url_2)
          .to_return(
            status: 200,
            body: document_body_2,
            headers: { 'Content-Type' => 'application/pdf' }
          )

        stub_request(:get, document_url_3)
          .to_return(
            status: 200,
            body: document_body_3,
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'succeeds with valid documents only' do
        expect(subject).to be_success
      end

      it 'includes only valid documents' do
        result = subject
        documents = result.bundled_data.data.actes_et_bilans

        expect(documents.size).to eq(2)
        expect(documents[0][:filename]).to eq("bilan_#{siren}_2.pdf")
        expect(documents[1][:filename]).to eq("bilan_#{siren}_3.pdf")
      end
    end

    context 'when all downloaded files are invalid' do
      before do
        stub_request(:get, document_url_1)
          .to_return(
            status: 200,
            body: 'Not a PDF - just some HTML error page content that is long enough to pass size check requiring over 100 bytes',
            headers: { 'Content-Type' => 'application/pdf' }
          )

        stub_request(:get, document_url_2)
          .to_return(
            status: 200,
            body: 'Also not a PDF - HTML content that is long enough to pass the minimum size check requiring over 100 bytes',
            headers: { 'Content-Type' => 'application/pdf' }
          )

        stub_request(:get, document_url_3)
          .to_return(
            status: 200,
            body: 'Another invalid file - HTML error that is long enough to pass the minimum size check requiring over 100 bytes',
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        expect(subject.error).to eq('Failed to download any documents')
      end
    end

    context 'with single document' do
      let(:resource) { Resource.new(actes_et_bilans: [document_url_1]) }

      before do
        stub_request(:get, document_url_1)
          .to_return(
            status: 200,
            body: document_body_1,
            headers: { 'Content-Type' => 'application/pdf' }
          )
      end

      it 'generates filename with index 1' do
        result = subject
        expect(result.bundled_data.data.actes_et_bilans[0][:filename]).to eq("bilan_#{siren}_1.pdf")
      end
    end
  end
end
