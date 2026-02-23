# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::PrepareDocumentScanStatus, type: :interactor do
  describe '.call' do
    let(:market_application) { create(:market_application) }
    let(:view_context) { double('view_context') }

    context 'when there are no file responses' do
      it 'succeeds' do
        result = described_class.call(market_application:, view_context:)

        expect(result).to be_success
      end

      it 'returns scans_complete as true' do
        result = described_class.call(market_application:, view_context:)

        expect(result.scan_status[:scans_complete]).to be true
      end

      it 'returns empty blob_states' do
        result = described_class.call(market_application:, view_context:)

        expect(result.scan_status[:blob_states]).to be_empty
      end
    end

    context 'when there are file responses with attached documents' do
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
      let!(:market_attribute_response) do
        response = MarketAttributeResponse.build_for_attribute(market_attribute, market_application:)
        response.documents.attach(blob)
        response.save!
        response
      end
      let(:badge_html) { '<span class="fr-badge">Scanning</span>' }

      before do
        market_application.reload
        allow(view_context).to receive(:dsfr_malware_badge).and_return(badge_html)
      end

      it 'succeeds' do
        result = described_class.call(market_application:, view_context:)

        expect(result).to be_success
      end

      it 'returns blob_states with blob_id and badge_html' do
        result = described_class.call(market_application:, view_context:)

        expect(result.scan_status[:blob_states]).to contain_exactly(
          a_hash_including(blob_id: blob.id, badge_html:)
        )
      end

      it 'calls dsfr_malware_badge on the view_context' do
        described_class.call(market_application:, view_context:)

        expect(view_context).to have_received(:dsfr_malware_badge).with(anything, class: 'fr-ml-1w')
      end

      it 'enqueues document scans' do
        allow(market_attribute_response).to receive(:enqueue_document_scans)
        file_responses = [market_attribute_response]
        allow(market_application).to receive(:market_attribute_responses).and_return(file_responses)
        allow(file_responses).to receive(:select).and_return(file_responses)

        described_class.call(market_application:, view_context:)

        expect(market_attribute_response).to have_received(:enqueue_document_scans)
      end

      context 'when scans are complete' do
        before do
          blob.update!(metadata: blob.metadata.merge('scan_safe' => true, 'scanned_at' => Time.current.iso8601))
        end

        it 'returns scans_complete as true' do
          result = described_class.call(market_application:, view_context:)

          expect(result.scan_status[:scans_complete]).to be true
        end
      end

      context 'when scans are not complete' do
        it 'returns scans_complete as false' do
          result = described_class.call(market_application:, view_context:)

          expect(result.scan_status[:scans_complete]).to be false
        end
      end
    end
  end
end
