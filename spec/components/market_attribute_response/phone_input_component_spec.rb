# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::PhoneInputComponent, type: :component do
  let(:market_attribute) { create(:market_attribute, :phone, :mandatory, key: 'contact_phone') }

  describe '#text_value' do
    context 'with text present' do
      it 'returns the text value' do
        response = create(:market_attribute_response_phone_input, market_attribute:, value: { 'text' => '01 23 45 67 89' })
        component = described_class.new(market_attribute_response: response)

        expect(component.text_value).to eq('01 23 45 67 89')
      end
    end

    context 'with text blank' do
      it 'returns empty string' do
        response = build_stubbed(:market_attribute_response_phone_input, market_attribute:, value: { 'text' => '' })
        component = described_class.new(market_attribute_response: response)

        expect(component.text_value).to eq('')
      end
    end

    context 'with nil value' do
      it 'returns empty string' do
        response = create(:market_attribute_response_phone_input, market_attribute:, source: :auto, value: nil)
        component = described_class.new(market_attribute_response: response)

        expect(component.text_value).to eq('')
      end
    end
  end

  describe '#display_value' do
    context 'with text present' do
      it 'returns the text value' do
        response = create(:market_attribute_response_phone_input, market_attribute:, value: { 'text' => '01 23 45 67 89' })
        component = described_class.new(market_attribute_response: response)

        expect(component.display_value).to eq('01 23 45 67 89')
      end
    end

    context 'with text blank' do
      it 'returns "Non renseigné"' do
        response = build_stubbed(:market_attribute_response_phone_input, market_attribute:, value: { 'text' => '' })
        component = described_class.new(market_attribute_response: response)

        expect(component.display_value).to eq('Non renseigné')
      end
    end
  end

  describe '#hint_text' do
    context 'without field description' do
      it 'returns default hint' do
        response = create(:market_attribute_response_phone_input, market_attribute:)
        component = described_class.new(market_attribute_response: response)

        expect(component.hint_text).to eq('Format attendu : 01 22 33 44 55')
      end
    end
  end

  describe 'form mode' do
    let(:form) { double('FormBuilder', object: double(id: 123)) }
    let(:response_form) { double('ResponseFormBuilder') }

    context 'with manual source' do
      it 'renders input group with telephone field' do
        response = create(:market_attribute_response_phone_input, market_attribute:, source: :manual, value: { 'text' => '01 23 45 67 89' })
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:label).and_yield
        allow(response_form).to receive(:telephone_field).and_return('<input type="tel">'.html_safe)

        render_inline(component)

        expect(page).to have_css('.fr-input-group')
      end

      it 'displays default hint text' do
        response = create(:market_attribute_response_phone_input, market_attribute:, source: :manual, value: { 'text' => '' })
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:label).and_yield
        allow(response_form).to receive(:telephone_field).and_return('<input type="tel">'.html_safe)

        render_inline(component)

        expect(page).to have_text('Format attendu : 01 22 33 44 55')
      end
    end

    context 'with auto source' do
      it 'renders hidden fields only' do
        response = create(:market_attribute_response_phone_input, market_attribute:, source: :auto, value: { 'text' => '01 98 76 54 32' })
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)

        render_inline(component)

        expect(response_form).to have_received(:hidden_field).with(:id)
        expect(response_form).to have_received(:hidden_field).with(:market_attribute_id)
        expect(response_form).to have_received(:hidden_field).with(:type)
        expect(response_form).to have_received(:hidden_field).with(:text, hash_including(value: '01 98 76 54 32'))
      end

      it 'renders auto-filled message' do
        response = create(:market_attribute_response_phone_input, market_attribute:, source: :auto, value: { 'text' => '01 98 76 54 32' })
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)

        render_inline(component)

        expect(page).to have_css('p.fr-text--sm.fr-text--mention-grey')
      end
    end

    context 'with manual_after_api_failure source' do
      it 'renders input group with telephone field' do
        response = create(:market_attribute_response_phone_input, market_attribute:, source: :manual_after_api_failure, value: { 'text' => '01 11 22 33 44' })
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:label).and_yield
        allow(response_form).to receive(:telephone_field).and_return('<input type="tel">'.html_safe)

        render_inline(component)

        expect(page).to have_css('.fr-input-group')
      end
    end

    context 'with errors' do
      it 'adds error CSS classes to input group' do
        response = build_stubbed(:market_attribute_response_phone_input, market_attribute:, source: :manual, value: { 'text' => 'invalid' })
        response.errors.add(:text, 'Format invalide')
        component = described_class.new(market_attribute_response: response, form:)

        expect(component.input_group_css_class).to eq('fr-input-group fr-input-group--error')
        expect(component.input_css_class).to eq('fr-input fr-input--error')
      end
    end
  end

  describe 'display mode' do
    context 'with manual source and web context' do
      it 'shows field label and value' do
        response = create(:market_attribute_response_phone_input, market_attribute:, source: :manual, value: { 'text' => '01 23 45 67 89' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).to have_css('strong')
        expect(page).to have_text('01 23 45 67 89')
      end
    end

    context 'with auto source and web context' do
      it 'shows field label but hides value' do
        response = create(:market_attribute_response_phone_input, market_attribute:, source: :auto, value: { 'text' => '01 98 76 54 32' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).to have_css('strong')
        expect(page).not_to have_text('01 98 76 54 32')
      end

      it 'renders source badge' do
        response = create(:market_attribute_response_phone_input, market_attribute:, source: :auto, value: { 'text' => '01 98 76 54 32' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('span.fr-badge.fr-badge--success')
      end
    end

    context 'with manual source and buyer context' do
      it 'shows field label and value' do
        response = create(:market_attribute_response_phone_input, market_attribute:, source: :manual, value: { 'text' => '01 23 45 67 89' })
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_text('01 23 45 67 89')
      end
    end

    context 'with auto source and buyer context' do
      it 'shows field label and value for buyer' do
        response = create(:market_attribute_response_phone_input, market_attribute:, source: :auto, value: { 'text' => '01 98 76 54 32' })
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_text('01 98 76 54 32')
      end
    end

    context 'with manual source and pdf context' do
      it 'shows field label and value' do
        response = create(:market_attribute_response_phone_input, market_attribute:, source: :manual, value: { 'text' => '01 23 45 67 89' })
        component = described_class.new(market_attribute_response: response, context: :pdf)

        render_inline(component)

        expect(page).to have_text('01 23 45 67 89')
      end
    end

    context 'with auto source and pdf context' do
      it 'hides value for candidate PDF' do
        response = create(:market_attribute_response_phone_input, market_attribute:, source: :auto, value: { 'text' => '01 98 76 54 32' })
        component = described_class.new(market_attribute_response: response, context: :pdf)

        render_inline(component)

        expect(page).not_to have_text('01 98 76 54 32')
      end
    end

    context 'with empty value' do
      it 'displays "Non renseigné"' do
        response = build_stubbed(:market_attribute_response_phone_input, market_attribute:, source: :manual, value: { 'text' => '' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('Non renseigné')
      end
    end
  end

  describe '#errors?' do
    it 'returns true when errors present' do
      response = build_stubbed(:market_attribute_response_phone_input, market_attribute:, value: { 'text' => 'invalid' })
      response.errors.add(:text, 'Error')
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be true
    end

    it 'returns false when no errors' do
      response = create(:market_attribute_response_phone_input, market_attribute:, value: { 'text' => '01 23 45 67 89' })
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be false
    end
  end

  describe '#input_id and #aria_describedby' do
    let(:form) { double('FormBuilder', object: double(id: 456)) }

    it 'generates correct input_id' do
      response = create(:market_attribute_response_phone_input, market_attribute:)
      component = described_class.new(market_attribute_response: response, form:)

      expect(component.input_id).to eq('phone-input-456')
    end

    it 'generates correct aria_describedby' do
      response = create(:market_attribute_response_phone_input, market_attribute:)
      component = described_class.new(market_attribute_response: response, form:)

      expect(component.aria_describedby).to eq('phone-input-456-messages')
    end
  end
end
