# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GeneratePublicMarketConfigurationSummaryPdfJob, type: :job do
  let(:public_market) { create(:public_market, :completed) }

  before do
    allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_return('fake pdf content')
  end

  describe '#perform' do
    it 'generates and attaches the configuration summary PDF' do
      described_class.perform_now(public_market.id)

      expect(public_market.reload.configuration_summary).to be_attached
    end

    it 'enqueues the webhook sync job after the PDF is generated' do
      expect do
        described_class.perform_now(public_market.id)
      end.to have_enqueued_job(PublicMarketWebhookJob).with(public_market.id)
    end

    context 'when configuration summary PDF generation fails' do
      before do
        allow(GeneratePublicMarketConfigurationSummaryPdf).to receive(:call)
          .and_return(instance_double(Interactor::Context, success?: false))
      end

      it 'still enqueues the webhook sync job' do
        expect do
          described_class.perform_now(public_market.id)
        end.to have_enqueued_job(PublicMarketWebhookJob).with(public_market.id)
      end
    end
  end
end
