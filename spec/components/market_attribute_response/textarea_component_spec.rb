# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::TextareaComponent, type: :component do
  let(:market_attribute) { create(:market_attribute, :textarea, :mandatory, key: 'company_description') }

  describe '#text_value' do
    context 'with text present' do
      it 'returns the text value' do
        response = create(:market_attribute_response_textarea, market_attribute:, value: { 'text' => 'Company description' })
        component = described_class.new(market_attribute_response: response)

        expect(component.text_value).to eq('Company description')
      end
    end

    context 'with text blank' do
      it 'returns empty string' do
        response = build_stubbed(:market_attribute_response_textarea, market_attribute:, value: { 'text' => '' })
        component = described_class.new(market_attribute_response: response)

        expect(component.text_value).to eq('')
      end
    end

    context 'with nil value' do
      it 'returns empty string' do
        response = create(:market_attribute_response_textarea, market_attribute:, source: :auto, value: nil)
        component = described_class.new(market_attribute_response: response)

        expect(component.text_value).to eq('')
      end
    end
  end

  describe '#display_value' do
    context 'with text present' do
      it 'returns the raw text value' do
        response = create(:market_attribute_response_textarea, market_attribute:, value: { 'text' => 'Line 1' })
        component = described_class.new(market_attribute_response: response)

        expect(component.display_value).to eq('Line 1')
      end
    end

    context 'with text blank' do
      it 'returns "Non renseigné"' do
        response = build_stubbed(:market_attribute_response_textarea, market_attribute:, value: { 'text' => '' })
        component = described_class.new(market_attribute_response: response)

        expect(component.display_value).to eq('Non renseigné')
      end
    end
  end

  describe 'form mode' do
    let(:form) { double('FormBuilder') }
    let(:response_form) { double('ResponseFormBuilder') }

    context 'with manual source' do
      it 'renders input group with textarea field component' do
        response = create(:market_attribute_response_textarea, market_attribute:, source: :manual, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:label).and_yield
        allow(response_form).to receive(:text_area).and_return('<textarea>Test</textarea>'.html_safe)

        render_inline(component)

        expect(page).to have_css('.fr-input-group')
      end
    end

    context 'with auto source' do
      it 'renders hidden fields only' do
        response = create(:market_attribute_response_textarea, market_attribute:, source: :auto, value: { 'text' => 'Auto value' })
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)

        render_inline(component)

        expect(response_form).to have_received(:hidden_field).with(:id)
        expect(response_form).to have_received(:hidden_field).with(:market_attribute_id)
        expect(response_form).to have_received(:hidden_field).with(:type)
        expect(response_form).to have_received(:hidden_field).with(:text, hash_including(value: 'Auto value'))
      end

      it 'renders auto-filled message' do
        response = create(:market_attribute_response_textarea, market_attribute:, source: :auto, value: { 'text' => 'Auto value' })
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)

        render_inline(component)

        expect(page).to have_css('p.fr-text--sm.fr-text--mention-grey')
      end
    end

    context 'with manual_after_api_failure source' do
      it 'renders input group with textarea' do
        response = create(:market_attribute_response_textarea, market_attribute:, source: :manual_after_api_failure, value: { 'text' => 'Fallback' })
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:label).and_yield
        allow(response_form).to receive(:text_area).and_return('<textarea>Fallback</textarea>'.html_safe)

        render_inline(component)

        expect(page).to have_css('.fr-input-group')
      end
    end

    context 'with errors' do
      it 'adds error CSS classes to input group' do
        response = build_stubbed(:market_attribute_response_textarea, market_attribute:, source: :manual, value: { 'text' => '' })
        response.errors.add(:text, 'Ce champ est requis')
        component = described_class.new(market_attribute_response: response, form:)

        expect(component.input_group_css_class).to eq('fr-input-group fr-input-group--error')
      end
    end
  end

  describe 'display mode' do
    context 'with manual source and web context' do
      it 'shows field label and value' do
        response = create(:market_attribute_response_textarea, market_attribute:, source: :manual, value: { 'text' => 'Company description' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).to have_css('strong')
        expect(page).to have_text('Company description')
      end
    end

    context 'with auto source and web context' do
      it 'shows field label but hides value' do
        response = create(:market_attribute_response_textarea, market_attribute:, source: :auto, value: { 'text' => 'Auto value' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).to have_css('strong')
        expect(page).not_to have_text('Auto value')
      end

      it 'renders source badge' do
        response = create(:market_attribute_response_textarea, market_attribute:, source: :auto, value: { 'text' => 'Auto value' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('span.fr-badge.fr-badge--success')
      end
    end

    context 'with manual source and buyer context' do
      it 'shows field label and value' do
        response = create(:market_attribute_response_textarea, market_attribute:, source: :manual, value: { 'text' => 'Company description' })
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_text('Company description')
      end
    end

    context 'with auto source and buyer context' do
      it 'shows field label and value for buyer' do
        response = create(:market_attribute_response_textarea, market_attribute:, source: :auto, value: { 'text' => 'Auto value' })
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_text('Auto value')
      end
    end

    context 'with manual source and pdf context' do
      it 'shows field label and value' do
        response = create(:market_attribute_response_textarea, market_attribute:, source: :manual, value: { 'text' => 'Company description' })
        component = described_class.new(market_attribute_response: response, context: :pdf)

        render_inline(component)

        expect(page).to have_text('Company description')
      end
    end

    context 'with auto source and pdf context' do
      it 'hides value for candidate PDF' do
        response = create(:market_attribute_response_textarea, market_attribute:, source: :auto, value: { 'text' => 'Auto value' })
        component = described_class.new(market_attribute_response: response, context: :pdf)

        render_inline(component)

        expect(page).not_to have_text('Auto value')
      end
    end

    context 'with empty value' do
      it 'displays "Non renseigné"' do
        response = build_stubbed(:market_attribute_response_textarea, market_attribute:, source: :manual, value: { 'text' => '' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('Non renseigné')
      end
    end
  end

  describe '#errors?' do
    it 'returns true when errors present' do
      response = build_stubbed(:market_attribute_response_textarea, market_attribute:, value: { 'text' => '' })
      response.errors.add(:text, 'Error')
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be true
    end

    it 'returns false when no errors' do
      response = create(:market_attribute_response_textarea, market_attribute:, value: { 'text' => 'Valid' })
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be false
    end
  end
end
