# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::DeleteAttachedFile, type: :interactor do
  describe '.call' do
    let(:market_application) { create(:market_application) }
    let(:market_attribute) do
      create(:market_attribute, :file_upload, public_markets: [market_application.public_market])
    end

    context 'when attachment exists and belongs to market_application' do
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

      it 'succeeds' do
        result = described_class.call(
          signed_id:,
          market_application:
        )

        expect(result).to be_success
      end

      it 'deletes the attachment' do
        expect do
          described_class.call(
            signed_id:,
            market_application:
          )
        end.to change { ActiveStorage::Attachment.count }.by(-1)
      end

      it 'enqueues blob purge job' do
        expect do
          described_class.call(
            signed_id:,
            market_application:
          )
        end.to have_enqueued_job(ActiveStorage::PurgeJob)
      end

      it 'sets deleted flag in context' do
        result = described_class.call(
          signed_id:,
          market_application:
        )

        expect(result.deleted).to be true
      end

      context 'when the application belongs to a co_traitant who had transmitted it' do
        let(:mandataire_application) do
          create(:market_application, public_market: market_application.public_market, siret: '80245139600099',
            application_mode: :groupement)
        end
        let(:grouping) do
          create(:grouping, public_market: market_application.public_market, mandataire_market_application: mandataire_application)
        end

        before { allow(SiretValidator).to receive(:valid?).and_return(true) }
        let!(:grouping_member) do
          create(:grouping_member, :co_traitant, grouping:, market_application:, siret: market_application.siret,
            status: :completed)
        end

        it 'moves the co_traitant back to in progress' do
          described_class.call(signed_id:, market_application:)

          expect(grouping_member.reload).to be_status_in_progress
        end

        it 'keeps the document once the grouping has been submitted' do
          grouping.update!(submitted_at: Time.current)

          result = described_class.call(signed_id:, market_application:)

          expect(result).to be_failure
          expect(ActiveStorage::Attachment.exists?(blob:)).to be true
          expect(grouping_member.reload).to be_status_completed
        end
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

    context 'when blob exists but has no attachment' do
      let!(:blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('test content'),
          filename: 'test.pdf',
          content_type: 'application/pdf'
        )
      end
      let(:signed_id) { blob.signed_id }

      it 'succeeds but does not delete' do
        result = described_class.call(
          signed_id:,
          market_application:
        )

        expect(result).to be_success
        expect(result.deleted).to be_nil
      end
    end

    context 'when attachment belongs to different market_application' do
      let(:other_market_application) { create(:market_application) }
      let(:other_market_attribute) do
        create(:market_attribute, :file_upload, public_markets: [other_market_application.public_market])
      end
      let!(:blob) do
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('test content'),
          filename: 'test.pdf',
          content_type: 'application/pdf'
        )
      end
      let(:signed_id) { blob.signed_id }
      let!(:other_response) do
        response = MarketAttributeResponse.build_for_attribute(other_market_attribute,
          market_application: other_market_application)
        response.documents.attach(blob)
        response.save!
        response
      end

      it 'fails' do
        result = described_class.call(
          signed_id:,
          market_application:
        )

        expect(result).to be_failure
      end

      it 'does not delete the attachment' do
        expect do
          described_class.call(
            signed_id:,
            market_application:
          )
        end.not_to change(ActiveStorage::Attachment, :count)
      end
    end
  end
end
