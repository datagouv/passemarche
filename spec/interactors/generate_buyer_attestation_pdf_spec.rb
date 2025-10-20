# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenerateBuyerAttestationPdf, type: :interactor do
  before do
    allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_return('fake pdf content')
  end
  let(:market_application) { create(:market_application, siret: nil) }

  describe '.call' do
    subject { described_class.call(market_application:) }

    context 'when no buyer attestation is attached' do
      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'attaches a buyer attestation PDF to the market application' do
        subject
        expect(market_application.buyer_attestation).to be_attached
        expect(market_application.buyer_attestation.content_type).to eq('application/pdf')
        expect(market_application.buyer_attestation.filename.to_s).to include("buyer_attestation_FT#{market_application.identifier}")
      end

      it 'sets the buyer_attestation in the context' do
        result = subject
        expect(result.buyer_attestation).to eq(market_application.buyer_attestation)
      end

      it 'generates PDF with "Attestation acheteur" header' do
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_call_original
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string) do |_instance, html_content, _options|
          expect(html_content).to include('Attestation acheteur')
          'fake pdf content'
        end

        subject
      end

      it 'includes API-sourced data (auto) in the PDF content' do
        # Create a text input market attribute
        market_attribute = create(:market_attribute,
          :text_input,
          key: 'test_field',
          public_markets: [market_application.public_market])

        # Create a response with source: :auto (API-sourced data)
        create(:market_attribute_response_text_input,
          market_application:,
          market_attribute:,
          text: 'API sourced value',
          source: :auto)

        market_application.reload

        # Mock WickedPdf to capture HTML content
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_call_original
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string) do |_instance, html_content, _options|
          # Verify API-sourced data is present in buyer attestation
          expect(html_content).to include('API sourced value')
          'fake pdf content'
        end

        subject
      end
    end

    context 'when buyer attestation is already attached' do
      before { market_application.buyer_attestation.attach(io: StringIO.new('test'), filename: 'test.pdf', content_type: 'application/pdf') }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'provides error message' do
        expect(subject.message).to eq('Attestation acheteur déjà générée')
      end
    end
  end
end
