# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::InlineFileUploadComponent, type: :component do
  let(:market_attribute) { create(:market_attribute, :inline_file_upload, :mandatory, key: 'certificate_document') }

  describe '#documents_attached?' do
    context 'with documents attached' do
      it 'returns true' do
        response = create(:market_attribute_response_inline_file_upload, market_attribute:)
        response.documents.attach(io: StringIO.new('test'), filename: 'test.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response)

        expect(component.documents_attached?).to be true
      end
    end

    context 'without documents attached' do
      it 'returns false' do
        response = create(:market_attribute_response_inline_file_upload, market_attribute:)
        component = described_class.new(market_attribute_response: response)

        expect(component.documents_attached?).to be false
      end
    end
  end

  describe '#qualiopi_metadata?' do
    context 'without qualiopi metadata' do
      it 'returns false' do
        response = create(:market_attribute_response_inline_file_upload, market_attribute:)
        component = described_class.new(market_attribute_response: response)

        expect(component.qualiopi_metadata?).to be false
      end
    end
  end

  describe 'form mode' do
    let(:form) { double('FormBuilder') }
    let(:response_form) { double('ResponseFormBuilder') }

    context 'with manual source' do
      it 'renders certificate-row layout' do
        response = create(:market_attribute_response_inline_file_upload, market_attribute:, source: :manual)
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:label).and_return('<label>'.html_safe)
        allow(response_form).to receive(:file_field).and_return('<input type="file">'.html_safe)
        allow(response_form).to receive(:object).and_return(response)

        render_inline(component)

        expect(page).to have_css('.certificate-row')
        expect(page).to have_css('hr.fr-hr')
      end
    end

    context 'with auto source without qualiopi metadata' do
      it 'renders auto-filled message' do
        response = create(:market_attribute_response_inline_file_upload, market_attribute:, source: :auto)
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)

        render_inline(component)

        expect(page).to have_css('p.fr-text--sm.fr-text--mention-grey')
      end
    end

    context 'with manual_after_api_failure source' do
      it 'renders certificate-row layout' do
        response = create(:market_attribute_response_inline_file_upload, market_attribute:, source: :manual_after_api_failure)
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:label).and_return('<label>'.html_safe)
        allow(response_form).to receive(:file_field).and_return('<input type="file">'.html_safe)
        allow(response_form).to receive(:object).and_return(response)

        render_inline(component)

        expect(page).to have_css('.certificate-row')
      end
    end
  end

  describe 'display mode' do
    context 'with manual source and web context' do
      it 'shows field label and horizontal separator' do
        response = create(:market_attribute_response_inline_file_upload, market_attribute:, source: :manual)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).to have_css('strong')
        expect(page).to have_css('hr.fr-hr')
      end

      it 'shows no documents message when no files' do
        response = create(:market_attribute_response_inline_file_upload, market_attribute:, source: :manual)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('Aucun fichier téléchargé')
      end

      it 'shows documents when attached' do
        response = create(:market_attribute_response_inline_file_upload, market_attribute:, source: :manual)
        response.documents.attach(io: StringIO.new('test'), filename: 'inline-test.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('inline-test.pdf')
      end
    end

    context 'with auto source and web context' do
      it 'shows field label but hides value' do
        response = create(:market_attribute_response_inline_file_upload, market_attribute:, source: :auto)
        response.documents.attach(io: StringIO.new('test'), filename: 'auto-inline.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).to have_css('strong')
        expect(page).not_to have_text('auto-inline.pdf')
      end

      it 'renders source badge' do
        response = create(:market_attribute_response_inline_file_upload, market_attribute:, source: :auto)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('span.fr-badge.fr-badge--success')
      end
    end

    context 'with manual source and buyer context' do
      it 'shows field label and documents' do
        response = create(:market_attribute_response_inline_file_upload, market_attribute:, source: :manual)
        response.documents.attach(io: StringIO.new('test'), filename: 'buyer-inline.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_text('buyer-inline.pdf')
      end
    end

    context 'with auto source and buyer context' do
      it 'shows documents for buyer' do
        response = create(:market_attribute_response_inline_file_upload, market_attribute:, source: :auto)
        response.documents.attach(io: StringIO.new('test'), filename: 'auto-buyer-inline.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_text('auto-buyer-inline.pdf')
      end
    end

    context 'with manual source and pdf context' do
      it 'shows documents' do
        response = create(:market_attribute_response_inline_file_upload, market_attribute:, source: :manual)
        response.documents.attach(io: StringIO.new('test'), filename: 'pdf-inline.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :pdf)

        render_inline(component)

        expect(page).to have_text('pdf-inline.pdf')
      end
    end

    context 'with auto source and pdf context' do
      it 'hides documents for candidate PDF' do
        response = create(:market_attribute_response_inline_file_upload, market_attribute:, source: :auto)
        response.documents.attach(io: StringIO.new('test'), filename: 'auto-pdf-inline.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :pdf)

        render_inline(component)

        expect(page).not_to have_text('auto-pdf-inline.pdf')
      end
    end
  end

  describe '#errors?' do
    it 'returns true when errors present' do
      response = build_stubbed(:market_attribute_response_inline_file_upload, market_attribute:)
      response.errors.add(:documents, 'Ce champ est requis')
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be true
    end

    it 'returns false when no errors' do
      response = create(:market_attribute_response_inline_file_upload, market_attribute:)
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be false
    end
  end
end
