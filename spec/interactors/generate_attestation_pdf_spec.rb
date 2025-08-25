# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenerateAttestationPdf, type: :interactor do
  before do
    allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_return('fake pdf content')
  end
  let(:market_application) { create(:market_application, siret: nil) }

  describe '.call' do
    subject { described_class.call(market_application:) }

    context 'when no attestation is attached' do
      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'attaches an attestation PDF to the market application' do
        subject
        expect(market_application.attestation).to be_attached
        expect(market_application.attestation.content_type).to eq('application/pdf')
        expect(market_application.attestation.filename.to_s).to include("attestation_FT#{market_application.identifier}")
      end

      it 'sets the attestation in the context' do
        result = subject
        expect(result.attestation).to eq(market_application.attestation)
      end
    end

    context 'when attestation is already attached' do
      before { market_application.attestation.attach(io: StringIO.new('test'), filename: 'test.pdf', content_type: 'application/pdf') }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'provides error message' do
        expect(subject.message).to eq('Attestation déjà générée')
      end
    end
  end
end
