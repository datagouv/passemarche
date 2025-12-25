# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::FileUploadComponent, type: :component do
  let(:market_attribute) { create(:market_attribute, :file_upload, :mandatory, key: 'company_documents') }

  describe '#documents_attached?' do
    context 'with documents attached' do
      it 'returns true' do
        response = create(:market_attribute_response_file_upload, market_attribute:)
        response.documents.attach(io: StringIO.new('test'), filename: 'test.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response)

        expect(component.documents_attached?).to be true
      end
    end

    context 'without documents attached' do
      it 'returns false' do
        response = create(:market_attribute_response_file_upload, market_attribute:)
        component = described_class.new(market_attribute_response: response)

        expect(component.documents_attached?).to be false
      end
    end
  end

  describe '#no_documents_message' do
    it 'returns the no documents message' do
      response = create(:market_attribute_response_file_upload, market_attribute:)
      component = described_class.new(market_attribute_response: response)

      expect(component.no_documents_message).to eq('Aucun fichier téléchargé')
    end
  end

  describe 'form mode' do
    let(:form) { double('FormBuilder') }
    let(:response_form) { double('ResponseFormBuilder') }

    context 'with manual source' do
      it 'renders upload group' do
        response = create(:market_attribute_response_file_upload, market_attribute:, source: :manual)
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:label).and_return('<label>'.html_safe)
        allow(response_form).to receive(:file_field).and_return('<input type="file">'.html_safe)
        allow(response_form).to receive(:object).and_return(response)

        render_inline(component)

        expect(page).to have_css('.fr-upload-group')
      end
    end

    context 'with auto source' do
      it 'renders hidden fields only' do
        response = create(:market_attribute_response_file_upload, market_attribute:, source: :auto)
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)

        render_inline(component)

        expect(response_form).to have_received(:hidden_field).with(:id)
        expect(response_form).to have_received(:hidden_field).with(:market_attribute_id)
        expect(response_form).to have_received(:hidden_field).with(:type)
      end

      it 'renders auto-filled message' do
        response = create(:market_attribute_response_file_upload, market_attribute:, source: :auto)
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)

        render_inline(component)

        expect(page).to have_css('p.fr-text--sm.fr-text--mention-grey')
      end
    end

    context 'with manual_after_api_failure source' do
      it 'renders upload group' do
        response = create(:market_attribute_response_file_upload, market_attribute:, source: :manual_after_api_failure)
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:label).and_return('<label>'.html_safe)
        allow(response_form).to receive(:file_field).and_return('<input type="file">'.html_safe)
        allow(response_form).to receive(:object).and_return(response)

        render_inline(component)

        expect(page).to have_css('.fr-upload-group')
      end
    end
  end

  describe 'display mode' do
    context 'with manual source and web context' do
      it 'shows field label' do
        response = create(:market_attribute_response_file_upload, market_attribute:, source: :manual)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).to have_css('strong')
      end

      it 'shows no documents message when no files' do
        response = create(:market_attribute_response_file_upload, market_attribute:, source: :manual)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('Aucun fichier téléchargé')
      end

      it 'shows documents when attached' do
        response = create(:market_attribute_response_file_upload, market_attribute:, source: :manual)
        response.documents.attach(io: StringIO.new('test'), filename: 'test.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('test.pdf')
      end
    end

    context 'with auto source and web context' do
      it 'shows field label but hides value' do
        response = create(:market_attribute_response_file_upload, market_attribute:, source: :auto)
        response.documents.attach(io: StringIO.new('test'), filename: 'auto.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).to have_css('strong')
        expect(page).not_to have_text('auto.pdf')
      end

      it 'renders source badge' do
        response = create(:market_attribute_response_file_upload, market_attribute:, source: :auto)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('span.fr-badge.fr-badge--success')
      end
    end

    context 'with manual source and buyer context' do
      it 'shows field label and documents' do
        response = create(:market_attribute_response_file_upload, market_attribute:, source: :manual)
        response.documents.attach(io: StringIO.new('test'), filename: 'buyer.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_text('buyer.pdf')
      end
    end

    context 'with auto source and buyer context' do
      it 'shows documents for buyer' do
        response = create(:market_attribute_response_file_upload, market_attribute:, source: :auto)
        response.documents.attach(io: StringIO.new('test'), filename: 'auto-buyer.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_text('auto-buyer.pdf')
      end
    end

    context 'with manual source and pdf context' do
      it 'shows documents' do
        response = create(:market_attribute_response_file_upload, market_attribute:, source: :manual)
        response.documents.attach(io: StringIO.new('test'), filename: 'pdf.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :pdf)

        render_inline(component)

        expect(page).to have_text('pdf.pdf')
      end
    end

    context 'with auto source and pdf context' do
      it 'hides documents for candidate PDF' do
        response = create(:market_attribute_response_file_upload, market_attribute:, source: :auto)
        response.documents.attach(io: StringIO.new('test'), filename: 'auto-pdf.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :pdf)

        render_inline(component)

        expect(page).not_to have_text('auto-pdf.pdf')
      end
    end
  end

  describe '#errors?' do
    it 'returns true when errors present' do
      response = build_stubbed(:market_attribute_response_file_upload, market_attribute:)
      response.errors.add(:documents, 'Ce champ est requis')
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be true
    end

    it 'returns false when no errors' do
      response = create(:market_attribute_response_file_upload, market_attribute:)
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be false
    end
  end
end
