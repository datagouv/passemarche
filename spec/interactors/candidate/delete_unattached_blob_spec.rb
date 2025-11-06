# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::DeleteUnattachedBlob, type: :interactor do
  describe '.call' do
    let(:market_application) { create(:market_application) }

    context 'when blob exists and has no attachment' do
      let!(:blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('test content'),
          filename: 'test.pdf',
          content_type: 'application/pdf'
        )
      end
      let(:signed_id) { blob.signed_id }

      it 'succeeds' do
        result = described_class.call(
          signed_id:,
          market_application:
        )

        expect(result).to be_success
      end

      it 'enqueues blob purge job' do
        expect do
          described_class.call(
            signed_id:,
            market_application:
          )
        end.to have_enqueued_job(ActiveStorage::PurgeJob).with(blob)
      end

      it 'sets deleted flag in context' do
        result = described_class.call(
          signed_id:,
          market_application:
        )

        expect(result.deleted).to be true
      end
    end

    context 'when signed_id is invalid' do
      let(:signed_id) { 'invalid-signed-id' }

      it 'fails' do
        result = described_class.call(
          signed_id:,
          market_application:
        )

        expect(result).to be_failure
      end

      it 'provides error message' do
        result = described_class.call(
          signed_id:,
          market_application:
        )

        expect(result.message).to be_present
      end
    end

    context 'when blob does not exist' do
      let(:signed_id) do
        blob = ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('test'),
          filename: 'test.pdf',
          content_type: 'application/pdf'
        )
        signed = blob.signed_id
        blob.purge
        signed
      end

      it 'fails' do
        result = described_class.call(
          signed_id:,
          market_application:
        )

        expect(result).to be_failure
      end

      it 'provides not_found error message' do
        result = described_class.call(
          signed_id:,
          market_application:
        )

        expect(result.message).to eq('not_found')
      end
    end

    context 'when blob already has an attachment' do
      let(:market_attribute) do
        create(:market_attribute, :file_upload, public_markets: [market_application.public_market])
      end
      let!(:blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('test content'),
          filename: 'test.pdf',
          content_type: 'application/pdf'
        )
      end
      let(:signed_id) { blob.signed_id }
      let!(:market_attribute_response) do
        response = MarketAttributeResponse.build_for_attribute(market_attribute,
          market_application:)
        response.documents.attach(blob)
        response.save!
        response
      end

      it 'succeeds but does not delete' do
        result = described_class.call(
          signed_id:,
          market_application:
        )

        expect(result).to be_success
        expect(result.deleted).to be_nil
        expect(ActiveStorage::Blob.exists?(blob.id)).to be true
      end
    end
  end
end
