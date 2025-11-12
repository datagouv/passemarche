# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CotisationRetraite::MergeResources, type: :interactor do
  let(:cibtp_document) do
    {
      io: StringIO.new('%PDF-1.4'),
      filename: 'attestation_cibtp_41816609600069.pdf',
      content_type: 'application/pdf',
      metadata: { source: 'api_cibtp', api_name: 'cibtp' }
    }
  end

  let(:cnetp_document) do
    {
      io: StringIO.new('%PDF-1.4'),
      filename: 'attestation_cnetp_418166096.pdf',
      content_type: 'application/pdf',
      metadata: { source: 'api_cnetp', api_name: 'cnetp' }
    }
  end

  describe '.call' do
    context 'when both CIBTP and CNETP documents are present' do
      let(:resource) { Resource.new(cibtp_document:, cnetp_document:) }
      let(:bundled_data) { BundledData.new(data: resource) }

      subject { described_class.call(bundled_data:) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates merged resource with both documents' do
        result = subject
        merged_data = result.bundled_data.data

        expect(merged_data.documents).to be_an(Array)
        expect(merged_data.documents.length).to eq(2)
      end

      it 'includes CIBTP document in documents array' do
        result = subject
        documents = result.bundled_data.data.documents

        cibtp_doc = documents.find { |doc| doc[:filename].include?('cibtp') }
        expect(cibtp_doc).to be_present
        expect(cibtp_doc[:content_type]).to eq('application/pdf')
      end

      it 'includes CNETP document in documents array' do
        result = subject
        documents = result.bundled_data.data.documents

        cnetp_doc = documents.find { |doc| doc[:filename].include?('cnetp') }
        expect(cnetp_doc).to be_present
        expect(cnetp_doc[:content_type]).to eq('application/pdf')
      end

      it 'sets status to success_both in context' do
        result = subject
        expect(result.bundled_data.context[:status]).to eq('success_both')
      end
    end

    context 'when only CIBTP document is present' do
      let(:resource) { Resource.new(cibtp_document:) }
      let(:bundled_data) { BundledData.new(data: resource) }

      subject { described_class.call(bundled_data:) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates merged resource with only CIBTP document' do
        result = subject
        documents = result.bundled_data.data.documents

        expect(documents.length).to eq(1)
        expect(documents.first[:filename]).to include('cibtp')
      end

      it 'sets status to success_partial in context' do
        result = subject
        expect(result.bundled_data.context[:status]).to eq('success_partial')
      end
    end

    context 'when only CNETP document is present' do
      let(:resource) { Resource.new(cnetp_document:) }
      let(:bundled_data) { BundledData.new(data: resource) }

      subject { described_class.call(bundled_data:) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates merged resource with only CNETP document' do
        result = subject
        documents = result.bundled_data.data.documents

        expect(documents.length).to eq(1)
        expect(documents.first[:filename]).to include('cnetp')
      end

      it 'sets status to success_partial in context' do
        result = subject
        expect(result.bundled_data.context[:status]).to eq('success_partial')
      end
    end

    context 'when neither document is present' do
      let(:resource) { Resource.new }
      let(:bundled_data) { BundledData.new(data: resource) }

      subject { described_class.call(bundled_data:) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'includes error message about both APIs failing' do
        expect(subject.error).to include('Both')
      end
    end

    context 'when bundled_data is missing' do
      subject { described_class.call }

      it 'fails' do
        expect(subject).to be_failure
      end
    end
  end
end
