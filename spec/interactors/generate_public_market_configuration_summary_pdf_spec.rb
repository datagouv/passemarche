# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GeneratePublicMarketConfigurationSummaryPdf, type: :interactor do
  before do
    allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_return('fake pdf content')
    allow(PdfWatermarkService).to receive(:call) { |pdf_content| pdf_content }
  end

  let(:public_market) { create(:public_market, :completed) }

  describe '.call' do
    subject { described_class.call(public_market:) }

    context 'when no configuration summary is attached yet' do
      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'attaches a configuration summary PDF to the public market' do
        subject
        expect(public_market.configuration_summary).to be_attached
        expect(public_market.configuration_summary.content_type).to eq('application/pdf')
        expect(public_market.configuration_summary.filename.to_s).to include("configuration_summary_#{public_market.identifier}")
      end

      it 'sets the configuration_summary in the context' do
        result = subject
        expect(result.configuration_summary).to eq(public_market.configuration_summary)
      end

      it 'generates PDF with the market name' do
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_call_original
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string) do |_instance, html_content, _options|
          expect(html_content).to include(ERB::Util.html_escape(public_market.name))
          'fake pdf content'
        end

        subject
      end
    end

    context 'when a configuration summary is already attached (re-transmission)' do
      before { public_market.configuration_summary.attach(io: StringIO.new('old'), filename: 'old.pdf', content_type: 'application/pdf') }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'replaces the previous configuration summary PDF' do
        old_blob_id = public_market.configuration_summary.blob.id

        subject
        public_market.reload

        expect(public_market.configuration_summary.blob.id).not_to eq(old_blob_id)
      end
    end

    context 'with multi-type lots' do
      let(:works_type) { MarketType.find_or_create_by!(code: 'works') }
      let(:services_type) { MarketType.find_or_create_by!(code: 'services') }
      let(:public_market) { create(:public_market, :multi_type, :completed) }

      let!(:common_attribute) do
        attribute = create(:market_attribute,
          key: 'common_field',
          category_key: 'common_cat',
          subcategory_key: 'common_sub',
          market_types: [works_type, services_type])
        public_market.add_market_attributes([attribute])
        attribute
      end

      it 'includes scope badges in the PDF content' do
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string).and_call_original
        allow_any_instance_of(WickedPdf).to receive(:pdf_from_string) do |_instance, html_content, _options|
          expect(html_content).to include(I18n.t('buyer.public_markets.form_config.scope_commun_badge'))
          'fake pdf content'
        end

        subject
      end
    end
  end
end
