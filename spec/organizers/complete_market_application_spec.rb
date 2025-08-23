# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CompleteMarketApplication, type: :organizer do
  before do
    allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_return('fake pdf content')
  end
  let(:market_application) { create(:market_application, siret: nil) }

  describe '.call' do
    subject { described_class.call(market_application: market_application) }

    context 'when all steps succeed' do
      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'marks application as completed' do
        expect { subject }
          .to change { market_application.reload.completed_at }
          .from(nil).to(be_present)
      end

      it 'generates attestation PDF' do
        expect { subject }
          .to change { market_application.reload.attestation.attached? }
          .from(false).to(true)
      end

      it 'sets both completed_at and attestation in context' do
        result = subject
        expect(result.completed_at).to be_present
        expect(result.attestation).to be_present
      end
    end

    context 'when PDF generation fails' do
      before do
        allow_any_instance_of(GenerateAttestationPdf).to receive(:call) do |instance|
          instance.context.fail!(message: 'PDF generation failed')
        end
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'does not attach attestation' do
        subject
        expect(market_application.reload.attestation).not_to be_attached
      end

      it 'provides error message' do
        expect(subject.message).to eq('PDF generation failed')
      end
    end

    context 'when application is already completed' do
      let(:market_application) { create(:market_application, siret: nil, completed_at: 1.hour.ago) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'provides error message' do
        expect(subject.message).to eq('Application already completed')
      end

      it 'does not modify existing completed_at' do
        original_time = market_application.completed_at
        subject
        expect(market_application.reload.completed_at).to eq(original_time)
      end
    end
  end
end
