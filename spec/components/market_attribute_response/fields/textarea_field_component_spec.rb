# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::Fields::TextareaFieldComponent, type: :component do
  let(:market_attribute) { create(:market_attribute, :textarea) }
  let(:attribute_response) do
    create(:market_attribute_response_textarea,
      market_attribute:,
      value: { 'text' => 'Sample text content' })
  end
  let(:form) { double('FormBuilder', object: attribute_response) }

  before do
    allow(form).to receive(:text_area).and_return('<textarea>Sample text content</textarea>'.html_safe)
  end

  describe '#text_value' do
    context 'with text present' do
      it 'returns the text value' do
        component = described_class.new(form:, attribute_response:)

        expect(component.text_value).to eq('Sample text content')
      end
    end

    context 'with nil value' do
      it 'returns empty string' do
        response = build_stubbed(:market_attribute_response_textarea, market_attribute:, value: nil)
        component = described_class.new(form:, attribute_response: response)

        expect(component.text_value).to eq('')
      end
    end

    context 'with empty text' do
      it 'returns empty string' do
        response = build_stubbed(:market_attribute_response_textarea, market_attribute:, value: { 'text' => '' })
        component = described_class.new(form:, attribute_response: response)

        expect(component.text_value).to eq('')
      end
    end
  end

  describe '#errors?' do
    context 'with no errors' do
      it 'returns false' do
        component = described_class.new(form:, attribute_response:)

        expect(component.errors?).to be false
      end
    end

    context 'with text errors' do
      it 'returns true' do
        attribute_response.errors.add(:text, 'Ce champ est requis')
        component = described_class.new(form:, attribute_response:)

        expect(component.errors?).to be true
      end
    end
  end

  describe '#error_message' do
    it 'returns the first error message' do
      attribute_response.errors.add(:text, 'Ce champ est requis')
      attribute_response.errors.add(:text, 'Autre erreur')
      component = described_class.new(form:, attribute_response:)

      expect(component.error_message).to eq('Ce champ est requis')
    end
  end

  describe '#input_group_css_class' do
    context 'without errors' do
      it 'returns base classes' do
        component = described_class.new(form:, attribute_response:)

        expect(component.input_group_css_class).to eq('fr-input-group fr-mb-2w')
      end
    end

    context 'with errors' do
      it 'includes error class' do
        attribute_response.errors.add(:text, 'Error')
        component = described_class.new(form:, attribute_response:)

        expect(component.input_group_css_class).to include('fr-input-group--error')
      end
    end
  end

  describe 'rendering' do
    it 'renders the input group container' do
      component = described_class.new(form:, attribute_response:)

      render_inline(component)

      expect(page).to have_css('.fr-input-group')
    end

    it 'calls form.text_area with correct options' do
      component = described_class.new(form:, attribute_response:, rows: 8)

      render_inline(component)

      expect(form).to have_received(:text_area).with(
        :text,
        hash_including(rows: 8, value: 'Sample text content', class: 'fr-input')
      )
    end

    context 'with readonly: true' do
      it 'passes readonly to text_area' do
        component = described_class.new(form:, attribute_response:, readonly: true)

        render_inline(component)

        expect(form).to have_received(:text_area).with(
          :text,
          hash_including(readonly: true)
        )
      end
    end

    context 'with errors' do
      it 'renders error text' do
        attribute_response.errors.add(:text, 'Ce champ est requis')
        component = described_class.new(form:, attribute_response:)

        render_inline(component)

        expect(page).to have_css('.fr-error-text', text: 'Ce champ est requis')
      end

      it 'adds error class to input group' do
        attribute_response.errors.add(:text, 'Error')
        component = described_class.new(form:, attribute_response:)

        render_inline(component)

        expect(page).to have_css('.fr-input-group--error')
      end
    end
  end
end
