# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Qualifelec::DownloadDocument, type: :interactor do
  let(:siret) { '78824266700020' }
  let(:siren) { '788242667' }
  let(:document_url_1) { 'https://qualifelec.example.com/certificat-1.jpg' }
  let(:document_url_2) { 'https://qualifelec.example.com/certificat-2.jpg' }
  let(:jpeg_header) { "\xFF\xD8\xFF".dup.force_encoding('ASCII-8BIT') }
  let(:document_body_1) { (jpeg_header.dup + ("\x00" * 200).force_encoding('ASCII-8BIT')) }
  let(:document_body_2) { (jpeg_header.dup + ("\x00" * 250).force_encoding('ASCII-8BIT')) }
  let(:resource) { Resource.new(documents: [document_url_1, document_url_2]) }
  let(:bundled_data) { BundledData.new(data: resource) }
  let(:token) { 'test-token-12345' }

  before do
    allow(Rails.application.credentials).to receive(:api_entreprise).and_return(
      OpenStruct.new(token:)
    )
  end

  describe '.call' do
    subject { described_class.call(bundled_data:, params: { siret: }, api_name: 'qualifelec') }

    context 'when multiple documents are successfully downloaded' do
      before do
        stub_request(:get, document_url_1)
          .to_return(
            status: 200,
            body: document_body_1,
            headers: { 'Content-Type' => 'image/jpeg' }
          )

        stub_request(:get, document_url_2)
          .to_return(
            status: 200,
            body: document_body_2,
            headers: { 'Content-Type' => 'image/jpeg' }
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

        documents.each do |document|
          expect(document).to be_a(Hash)
          expect(document[:io]).to be_a(StringIO)
          expect(document[:content_type]).to eq('image/jpeg')
        end
      end

      it 'generates unique filenames with index' do
        result = subject
        documents = result.bundled_data.data.documents

        expect(documents[0][:filename]).to eq("certificat_qualifelec_#{siren}_1.jpg")
        expect(documents[1][:filename]).to eq("certificat_qualifelec_#{siren}_2.jpg")
      end

      it 'includes metadata for each document' do
        result = subject
        documents = result.bundled_data.data.documents

        documents.each do |document|
          metadata = document[:metadata]
          expect(metadata).to include(
            source: 'api_qualifelec',
            api_name: 'qualifelec',
            downloaded_at: be_a(String)
          )
        end
      end
    end

    context 'when documents array is empty' do
      let(:resource) { Resource.new(documents: []) }

      it 'succeeds with empty array' do
        result = subject
        expect(result).to be_success
        expect(result.bundled_data.data.documents).to eq([])
      end
    end

    context 'when documents key is missing' do
      let(:resource) { Resource.new }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message about missing documents' do
        expect(subject.error).to eq('Missing documents in response')
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
            headers: { 'Content-Type' => 'image/jpeg' }
          )
      end

      it 'succeeds with partial results' do
        expect(subject).to be_success
      end

      it 'includes only successfully downloaded documents' do
        result = subject
        documents = result.bundled_data.data.documents

        expect(documents.size).to eq(1)
        expect(documents[0][:io]).to be_a(StringIO)
        expect(documents[0][:filename]).to eq("certificat_qualifelec_#{siren}_2.jpg")
      end
    end

    context 'when all document downloads fail' do
      before do
        stub_request(:get, document_url_1)
          .to_return(status: 404, body: 'Not Found')

        stub_request(:get, document_url_2)
          .to_return(status: 500, body: 'Server Error')
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message' do
        expect(subject.error).to eq('Failed to download any documents')
      end
    end

    context 'when one downloaded file is not a valid image' do
      before do
        stub_request(:get, document_url_1)
          .to_return(
            status: 200,
            body: 'Not an image - just some HTML error page content that is long enough to pass size check requiring over 100 bytes',
            headers: { 'Content-Type' => 'image/jpeg' }
          )

        stub_request(:get, document_url_2)
          .to_return(
            status: 200,
            body: document_body_2,
            headers: { 'Content-Type' => 'image/jpeg' }
          )
      end

      it 'succeeds with valid documents only' do
        expect(subject).to be_success
      end

      it 'includes only valid documents' do
        result = subject
        documents = result.bundled_data.data.documents

        expect(documents.size).to eq(1)
        expect(documents[0][:filename]).to eq("certificat_qualifelec_#{siren}_2.jpg")
      end
    end

    context 'when all downloaded files are invalid' do
      before do
        stub_request(:get, document_url_1)
          .to_return(
            status: 200,
            body: 'Not an image - just some HTML error page content that is long enough to pass size check requiring over 100 bytes',
            headers: { 'Content-Type' => 'image/jpeg' }
          )

        stub_request(:get, document_url_2)
          .to_return(
            status: 200,
            body: 'Also not an image - HTML content that is long enough to pass the minimum size check requiring over 100 bytes',
            headers: { 'Content-Type' => 'image/jpeg' }
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
      let(:resource) { Resource.new(documents: [document_url_1]) }

      before do
        stub_request(:get, document_url_1)
          .to_return(
            status: 200,
            body: document_body_1,
            headers: { 'Content-Type' => 'image/jpeg' }
          )
      end

      it 'generates filename with index 1' do
        result = subject
        expect(result.bundled_data.data.documents[0][:filename]).to eq("certificat_qualifelec_#{siren}_1.jpg")
      end
    end
  end
end
