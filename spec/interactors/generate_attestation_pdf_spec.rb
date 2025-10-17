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

      it 'generates PDF with "Attestation de candidature" header' do
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_call_original
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string) do |_instance, html_content, _options|
          expect(html_content).to include('Attestation de candidature')
          'fake pdf content'
        end

        subject
      end

      it 'hides API-sourced data (auto) from the PDF content' do
        # Create a text input market attribute
        market_attribute = create(:market_attribute,
          :text_input,
          key: 'test_field',
          public_markets: [market_application.public_market])

        # Create a response with source: :auto (API-sourced data)
        create(:market_attribute_response_text_input,
          market_application:,
          market_attribute:,
          text: 'API sourced value should be hidden',
          source: :auto)

        market_application.reload

        # Mock WickedPdf to capture HTML content
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_call_original
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string) do |_instance, html_content, _options|
          # Verify API-sourced data is NOT present in candidate attestation
          expect(html_content).not_to include('API sourced value should be hidden')
          'fake pdf content'
        end

        subject
      end

      it 'shows manually-entered data in the PDF content' do
        # Create a text input market attribute
        market_attribute = create(:market_attribute,
          :text_input,
          key: 'test_field',
          public_markets: [market_application.public_market])

        # Create a response with source: :manual
        create(:market_attribute_response_text_input,
          market_application:,
          market_attribute:,
          text: 'Manual value should be visible',
          source: :manual)

        market_application.reload

        # Mock WickedPdf to capture HTML content
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_call_original
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string) do |_instance, html_content, _options|
          # Verify manually-entered data IS present in candidate attestation
          expect(html_content).to include('Manual value should be visible')
          'fake pdf content'
        end

        subject
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
