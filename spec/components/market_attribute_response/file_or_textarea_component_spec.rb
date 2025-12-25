# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::FileOrTextareaComponent, type: :component do
  let(:market_attribute) { create(:market_attribute, :file_or_textarea, :mandatory, key: 'description_or_file') }

  describe '#text_value' do
    context 'with text present' do
      it 'returns the text value' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:, value: { 'text' => 'Sample description' })
        component = described_class.new(market_attribute_response: response)

        expect(component.text_value).to eq('Sample description')
      end
    end

    context 'with text blank' do
      it 'returns empty string' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:, value: { 'text' => '' })
        component = described_class.new(market_attribute_response: response)

        expect(component.text_value).to eq('')
      end
    end

    context 'with nil value' do
      it 'returns empty string' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:, value: nil)
        component = described_class.new(market_attribute_response: response)

        expect(component.text_value).to eq('')
      end
    end
  end

  describe '#text?' do
    it 'returns true when text present' do
      response = create(:market_attribute_response_file_or_textarea, market_attribute:, value: { 'text' => 'Content' })
      component = described_class.new(market_attribute_response: response)

      expect(component.text?).to be true
    end

    it 'returns false when text blank' do
      response = create(:market_attribute_response_file_or_textarea, market_attribute:, value: { 'text' => '' })
      component = described_class.new(market_attribute_response: response)

      expect(component.text?).to be false
    end
  end

  describe '#documents_attached?' do
    context 'with documents attached' do
      it 'returns true' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:)
        response.documents.attach(io: StringIO.new('test'), filename: 'test.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response)

        expect(component.documents_attached?).to be true
      end
    end

    context 'without documents attached' do
      it 'returns false' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:)
        component = described_class.new(market_attribute_response: response)

        expect(component.documents_attached?).to be false
      end
    end
  end

  describe 'form mode' do
    let(:form) { double('FormBuilder') }
    let(:response_form) { double('ResponseFormBuilder') }

    context 'with manual source' do
      it 'renders both file upload and textarea fields' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:, source: :manual, value: { 'text' => '' })
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:label).and_return('<label>'.html_safe)
        allow(response_form).to receive(:file_field).and_return('<input type="file">'.html_safe)
        allow(response_form).to receive(:text_area).and_return('<textarea>'.html_safe)
        allow(response_form).to receive(:object).and_return(response)

        render_inline(component)

        expect(page).to have_text('OU')
      end
    end

    context 'with auto source' do
      it 'renders auto-filled message' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:, source: :auto)
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)

        render_inline(component)

        expect(page).to have_css('p.fr-text--sm.fr-text--mention-grey')
      end
    end

    context 'with manual_after_api_failure source' do
      it 'renders both file upload and textarea fields' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:, source: :manual_after_api_failure, value: { 'text' => '' })
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:label).and_return('<label>'.html_safe)
        allow(response_form).to receive(:file_field).and_return('<input type="file">'.html_safe)
        allow(response_form).to receive(:text_area).and_return('<textarea>'.html_safe)
        allow(response_form).to receive(:object).and_return(response)

        render_inline(component)

        expect(page).to have_text('OU')
      end
    end
  end

  describe 'display mode' do
    context 'with manual source and web context' do
      it 'shows field label' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:, source: :manual)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).to have_css('strong')
      end

      it 'shows no content message when empty' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:, source: :manual, value: { 'text' => '' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('Aucune description ni fichier fourni')
      end

      it 'shows text when present' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:, source: :manual, value: { 'text' => 'My description' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('Description :')
        expect(page).to have_text('My description')
      end

      it 'shows documents when attached' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:, source: :manual, value: { 'text' => '' })
        response.documents.attach(io: StringIO.new('test'), filename: 'test.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('test.pdf')
      end

      it 'shows both text and documents when both present' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:, source: :manual, value: { 'text' => 'Text content' })
        response.documents.attach(io: StringIO.new('test'), filename: 'both.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('Text content')
        expect(page).to have_text('both.pdf')
      end
    end

    context 'with auto source and web context' do
      it 'shows field label but hides value' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:, source: :auto, value: { 'text' => 'Auto text' })
        response.documents.attach(io: StringIO.new('test'), filename: 'auto.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).not_to have_text('Auto text')
        expect(page).not_to have_text('auto.pdf')
      end

      it 'renders source badge' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:, source: :auto)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('span.fr-badge.fr-badge--success')
      end
    end

    context 'with auto source and buyer context' do
      it 'shows text and documents for buyer' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:, source: :auto, value: { 'text' => 'Buyer text' })
        response.documents.attach(io: StringIO.new('test'), filename: 'buyer.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_text('Buyer text')
        expect(page).to have_text('buyer.pdf')
      end
    end

    context 'with manual source and pdf context' do
      it 'shows text and documents' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:, source: :manual, value: { 'text' => 'PDF text' })
        response.documents.attach(io: StringIO.new('test'), filename: 'pdf.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :pdf)

        render_inline(component)

        expect(page).to have_text('PDF text')
        expect(page).to have_text('pdf.pdf')
      end
    end

    context 'with auto source and pdf context' do
      it 'hides value for candidate PDF' do
        response = create(:market_attribute_response_file_or_textarea, market_attribute:, source: :auto, value: { 'text' => 'Auto PDF text' })
        component = described_class.new(market_attribute_response: response, context: :pdf)

        render_inline(component)

        expect(page).not_to have_text('Auto PDF text')
      end
    end
  end

  describe '#errors?' do
    it 'returns true when errors present' do
      response = build_stubbed(:market_attribute_response_file_or_textarea, market_attribute:)
      response.errors.add(:value, 'Error')
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be true
    end

    it 'returns false when no errors' do
      response = create(:market_attribute_response_file_or_textarea, market_attribute:, value: { 'text' => 'Valid' })
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be false
    end
  end
end
