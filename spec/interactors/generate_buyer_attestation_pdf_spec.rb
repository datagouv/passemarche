# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenerateBuyerAttestationPdf, type: :interactor do
  before do
    allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_return('fake pdf content')
  end
  let(:market_application) { create(:market_application) }

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
        market_attribute = create(:market_attribute,
          :text_input,
          key: 'test_field',
          public_markets: [market_application.public_market])

        create(:market_attribute_response_text_input,
          market_application:,
          market_attribute:,
          text: 'API sourced value',
          source: :auto)

        market_application.reload

        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_call_original
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string) do |_instance, html_content, _options|
          expect(html_content).to include('API sourced value')
          'fake pdf content'
        end

        subject
      end

      context 'with motifs_exclusion category' do
        let(:market_application) { create(:market_application, attests_no_exclusion_motifs: true) }

        before do
          create(:market_attribute,
            :text_input,
            key: 'test_motif_field',
            category_key: 'motifs_exclusion',
            subcategory_key: 'motifs_exclusion_fiscales_et_sociales',
            public_markets: [market_application.public_market])
        end

        it 'includes candidate attestation block when attests_no_exclusion_motifs is true' do
          allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_call_original
          allow_any_instance_of(WickedPdf).to receive(:pdf_from_string) do |_instance, html_content, _options|
            expect(html_content).to include('Les motifs d&#39;exclusion')
            normalized_content = normalize_apostrophes(html_content)
            expected_text = normalize_apostrophes("J'atteste sur l'honneur que mon entreprise n'est concernée par aucun motif d'exclusion.")
            expect(normalized_content).to include(expected_text)
            'fake pdf content'
          end

          subject
        end

        it 'includes candidate attestation block when attests_no_exclusion_motifs is false' do
          market_application.update!(attests_no_exclusion_motifs: false)

          allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_call_original
          allow_any_instance_of(WickedPdf).to receive(:pdf_from_string) do |_instance, html_content, _options|
            expect(html_content).to include('Les motifs d&#39;exclusion')
            expect(html_content).to include('L&#39;attestation sur l&#39;honneur est manquante.')
            'fake pdf content'
          end

          subject
        end
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
