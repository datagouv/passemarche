# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::CheckboxWithDocumentComponent, type: :component do
  let(:market_attribute) { create(:market_attribute, :checkbox_with_document, :mandatory, key: 'test_checkbox_with_document') }

  describe '#checked?' do
    context 'when checked is true' do
      it 'returns true' do
        response = create(:market_attribute_response_checkbox_with_document, market_attribute:, value: { 'checked' => true })
        component = described_class.new(market_attribute_response: response)

        expect(component.checked?).to be true
      end
    end

    context 'when checked is false' do
      it 'returns false' do
        response = create(:market_attribute_response_checkbox_with_document, market_attribute:, value: { 'checked' => false })
        component = described_class.new(market_attribute_response: response)

        expect(component.checked?).to be false
      end
    end
  end

  describe '#documents_attached?' do
    context 'with documents attached' do
      it 'returns true' do
        response = create(:market_attribute_response_checkbox_with_document, market_attribute:, value: { 'checked' => true })
        response.documents.attach(io: StringIO.new('test'), filename: 'test.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response)

        expect(component.documents_attached?).to be true
      end
    end

    context 'without documents attached' do
      it 'returns false' do
        response = create(:market_attribute_response_checkbox_with_document, market_attribute:, value: { 'checked' => false })
        component = described_class.new(market_attribute_response: response)

        expect(component.documents_attached?).to be false
      end
    end
  end

  describe '#checkbox_label' do
    it 'returns translated label' do
      response = create(:market_attribute_response_checkbox_with_document, market_attribute:, value: { 'checked' => true })
      component = described_class.new(market_attribute_response: response)

      expect(component.checkbox_label).to be_present
    end
  end

  describe '#unchecked_message' do
    it 'returns unchecked message' do
      response = create(:market_attribute_response_checkbox_with_document, market_attribute:, value: { 'checked' => false })
      component = described_class.new(market_attribute_response: response)

      expect(component.unchecked_message).to eq('Non certifié')
    end
  end

  describe 'form mode' do
    let(:form) { double('FormBuilder') }
    let(:response_form) { double('ResponseFormBuilder') }

    context 'with manual source' do
      it 'renders checkbox and file upload' do
        response = create(:market_attribute_response_checkbox_with_document, market_attribute:, source: :manual, value: { 'checked' => false })
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:check_box).and_return('<input type="checkbox">'.html_safe)
        allow(response_form).to receive(:label) do |*_args, &block|
          block&.call
          '<label>'.html_safe
        end
        allow(response_form).to receive(:file_field).and_return('<input type="file">'.html_safe)
        allow(response_form).to receive(:object).and_return(response)

        render_inline(component)

        expect(page).to have_css('div.fr-checkbox-group')
      end
    end

    context 'with auto source' do
      it 'renders auto-filled message' do
        response = create(:market_attribute_response_checkbox_with_document, market_attribute:, source: :auto, value: { 'checked' => true })
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)

        render_inline(component)

        expect(page).to have_css('p.fr-text--sm.fr-text--mention-grey')
      end
    end
  end

  describe 'display mode' do
    context 'with manual source and web context' do
      it 'shows field label' do
        response = create(:market_attribute_response_checkbox_with_document, market_attribute:, source: :manual, value: { 'checked' => false })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).to have_css('strong')
      end

      it 'shows unchecked message when not checked' do
        response = create(:market_attribute_response_checkbox_with_document, market_attribute:, source: :manual, value: { 'checked' => false })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('Non certifié')
      end

      it 'shows checkbox label when checked' do
        response = create(:market_attribute_response_checkbox_with_document, market_attribute:, source: :manual, value: { 'checked' => true })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('.fr-text-md')
      end

      it 'shows documents when checked and attached' do
        response = create(:market_attribute_response_checkbox_with_document, market_attribute:, source: :manual, value: { 'checked' => true })
        response.documents.attach(io: StringIO.new('test'), filename: 'test.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('test.pdf')
      end
    end

    context 'with auto source and web context' do
      it 'shows field label but hides value' do
        response = create(:market_attribute_response_checkbox_with_document, market_attribute:, source: :auto, value: { 'checked' => true })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).not_to have_text('Non certifié')
      end

      it 'renders source badge' do
        response = create(:market_attribute_response_checkbox_with_document, market_attribute:, source: :auto, value: { 'checked' => true })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('span.fr-badge.fr-badge--success')
      end
    end

    context 'with auto source and buyer context' do
      it 'shows checkbox state for buyer' do
        response = create(:market_attribute_response_checkbox_with_document, market_attribute:, source: :auto, value: { 'checked' => true })
        response.documents.attach(io: StringIO.new('test'), filename: 'buyer.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_text('buyer.pdf')
      end
    end
  end

  describe '#errors?' do
    it 'returns true when checked errors present' do
      response = build_stubbed(:market_attribute_response_checkbox_with_document, market_attribute:)
      response.errors.add(:checked, 'Error')
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be true
    end

    it 'returns true when documents errors present' do
      response = build_stubbed(:market_attribute_response_checkbox_with_document, market_attribute:)
      response.errors.add(:documents, 'Error')
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be true
    end

    it 'returns false when no errors' do
      response = create(:market_attribute_response_checkbox_with_document, market_attribute:, value: { 'checked' => true })
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be false
    end
  end
end
