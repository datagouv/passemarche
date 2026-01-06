# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::InlineUrlInputComponent, type: :component do
  let(:market_attribute) { create(:market_attribute, :inline_url_input, :mandatory, key: 'certificate_url') }

  describe '#text_value' do
    context 'with text present' do
      it 'returns the text value' do
        response = create(:market_attribute_response_inline_url_input, market_attribute:, value: { 'text' => 'https://example.com' })
        component = described_class.new(market_attribute_response: response)

        expect(component.text_value).to eq('https://example.com')
      end
    end

    context 'with text blank' do
      it 'returns empty string' do
        response = build_stubbed(:market_attribute_response_inline_url_input, market_attribute:, value: { 'text' => '' })
        component = described_class.new(market_attribute_response: response)

        expect(component.text_value).to eq('')
      end
    end
  end

  describe '#display_value' do
    context 'with text present' do
      it 'returns the text value' do
        response = create(:market_attribute_response_inline_url_input, market_attribute:, value: { 'text' => 'https://example.com' })
        component = described_class.new(market_attribute_response: response)

        expect(component.display_value).to eq('https://example.com')
      end
    end

    context 'with text blank' do
      it 'returns default message' do
        response = build_stubbed(:market_attribute_response_inline_url_input, market_attribute:, value: { 'text' => '' })
        component = described_class.new(market_attribute_response: response)

        expect(component.display_value).to eq('Certificat non renseigné')
      end
    end
  end

  describe '#opqibi_field?' do
    it 'returns true for opqibi key' do
      opqibi_attribute = create(:market_attribute, :inline_url_input, key: 'capacites_techniques_professionnelles_certificats_opqibi')
      response = create(:market_attribute_response_inline_url_input, market_attribute: opqibi_attribute)
      component = described_class.new(market_attribute_response: response)

      expect(component.opqibi_field?).to be true
    end

    it 'returns false for other keys' do
      response = create(:market_attribute_response_inline_url_input, market_attribute:)
      component = described_class.new(market_attribute_response: response)

      expect(component.opqibi_field?).to be false
    end
  end

  describe '#france_competences_field?' do
    it 'returns true for france competences key' do
      fc_attribute = create(:market_attribute, :inline_url_input, key: 'capacites_techniques_professionnelles_certificats_france_competences')
      response = create(:market_attribute_response_inline_url_input, market_attribute: fc_attribute)
      component = described_class.new(market_attribute_response: response)

      expect(component.france_competences_field?).to be true
    end

    it 'returns false for other keys' do
      response = create(:market_attribute_response_inline_url_input, market_attribute:)
      component = described_class.new(market_attribute_response: response)

      expect(component.france_competences_field?).to be false
    end
  end

  describe 'form mode' do
    let(:form) { double('FormBuilder') }
    let(:response_form) { double('ResponseFormBuilder') }

    context 'with manual source' do
      it 'renders certificate-row layout with URL input' do
        response = create(:market_attribute_response_inline_url_input, market_attribute:, source: :manual, value: { 'text' => 'https://test.com' })
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:label).and_return('<label>'.html_safe)
        allow(response_form).to receive(:text_field).and_return('<input type="text">'.html_safe)

        render_inline(component)

        expect(page).to have_css('.certificate-row')
      end
    end

    context 'with auto source without special metadata' do
      it 'renders auto-filled message' do
        response = create(:market_attribute_response_inline_url_input, market_attribute:, source: :auto)
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)

        render_inline(component)

        expect(page).to have_css('.certificate-row')
        expect(page).to have_css('p.fr-text--sm.fr-text--mention-grey')
      end
    end

    context 'with manual_after_api_failure source' do
      it 'renders certificate-row layout with URL input' do
        response = create(:market_attribute_response_inline_url_input, market_attribute:, source: :manual_after_api_failure, value: { 'text' => '' })
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:label).and_return('<label>'.html_safe)
        allow(response_form).to receive(:text_field).and_return('<input type="text">'.html_safe)

        render_inline(component)

        expect(page).to have_css('.certificate-row')
      end
    end

    context 'with errors' do
      it 'adds error CSS classes' do
        response = build_stubbed(:market_attribute_response_inline_url_input, market_attribute:, source: :manual, value: { 'text' => 'invalid' })
        response.errors.add(:text, 'Format URL invalide')
        component = described_class.new(market_attribute_response: response, form:)

        expect(component.input_css_class).to eq('fr-input fr-input--error')
      end
    end
  end

  describe 'display mode' do
    context 'with manual source and web context' do
      it 'shows field label and URL link' do
        response = create(:market_attribute_response_inline_url_input, market_attribute:, source: :manual, value: { 'text' => 'https://example.com' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).to have_css('strong')
        expect(page).to have_link('https://example.com')
        expect(page).to have_css('hr.fr-hr')
      end

      it 'shows default message when no URL' do
        response = create(:market_attribute_response_inline_url_input, market_attribute:, source: :manual, value: { 'text' => '' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('Certificat non renseigné')
      end
    end

    context 'with auto source and web context' do
      it 'shows field label but hides value' do
        response = create(:market_attribute_response_inline_url_input, market_attribute:, source: :auto, value: { 'text' => 'https://auto.com' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).to have_css('strong')
        expect(page).not_to have_link('https://auto.com')
      end

      it 'renders source badge' do
        response = create(:market_attribute_response_inline_url_input, market_attribute:, source: :auto)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('span.fr-badge.fr-badge--success')
      end
    end

    context 'with manual source and buyer context' do
      it 'shows field label and URL link' do
        response = create(:market_attribute_response_inline_url_input, market_attribute:, source: :manual, value: { 'text' => 'https://buyer.com' })
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_link('https://buyer.com')
      end
    end

    context 'with auto source and buyer context' do
      it 'shows URL for buyer' do
        response = create(:market_attribute_response_inline_url_input, market_attribute:, source: :auto, value: { 'text' => 'https://auto-buyer.com' })
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_link('https://auto-buyer.com')
      end
    end

    context 'with manual source and pdf context' do
      it 'shows URL' do
        response = create(:market_attribute_response_inline_url_input, market_attribute:, source: :manual, value: { 'text' => 'https://pdf.com' })
        component = described_class.new(market_attribute_response: response, context: :pdf)

        render_inline(component)

        expect(page).to have_link('https://pdf.com')
      end
    end

    context 'with auto source and pdf context' do
      it 'hides URL for candidate PDF' do
        response = create(:market_attribute_response_inline_url_input, market_attribute:, source: :auto, value: { 'text' => 'https://auto-pdf.com' })
        component = described_class.new(market_attribute_response: response, context: :pdf)

        render_inline(component)

        expect(page).not_to have_link('https://auto-pdf.com')
      end
    end
  end

  describe '#errors?' do
    it 'returns true when errors present' do
      response = build_stubbed(:market_attribute_response_inline_url_input, market_attribute:, value: { 'text' => 'invalid' })
      response.errors.add(:text, 'Error')
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be true
    end

    it 'returns false when no errors' do
      response = create(:market_attribute_response_inline_url_input, market_attribute:, value: { 'text' => 'https://valid.com' })
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be false
    end
  end
end
