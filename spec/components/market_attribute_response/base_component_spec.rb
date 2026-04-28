# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::BaseComponent, type: :component do
  let(:market_attribute) { create(:market_attribute, :text_input, key: 'test_field') }

  describe '#form_mode?' do
    context 'with form builder' do
      it 'returns true' do
        response = create(:market_attribute_response_text_input, market_attribute:, value: { 'text' => 'Test' })
        form = double('FormBuilder')
        component = described_class.new(market_attribute_response: response, form:)

        expect(component.form_mode?).to be true
      end
    end

    context 'without form builder' do
      it 'returns false' do
        response = create(:market_attribute_response_text_input, market_attribute:, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response)

        expect(component.form_mode?).to be false
      end
    end
  end

  describe '#display_mode?' do
    context 'with form builder' do
      it 'returns false' do
        response = create(:market_attribute_response_text_input, market_attribute:, value: { 'text' => 'Test' })
        form = double('FormBuilder')
        component = described_class.new(market_attribute_response: response, form:)

        expect(component.display_mode?).to be false
      end
    end

    context 'without form builder' do
      it 'returns true' do
        response = create(:market_attribute_response_text_input, market_attribute:, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response)

        expect(component.display_mode?).to be true
      end
    end
  end

  describe '#manual?' do
    context 'with manual source' do
      it 'returns true' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response)

        expect(component.manual?).to be true
      end
    end

    context 'with manual_after_api_failure source' do
      it 'returns true' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual_after_api_failure, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response)

        expect(component.manual?).to be true
      end
    end

    context 'with auto source' do
      it 'returns false' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :auto, value: { 'text' => 'Auto' })
        component = described_class.new(market_attribute_response: response)

        expect(component.manual?).to be false
      end
    end
  end

  describe '#auto?' do
    context 'with auto source' do
      it 'returns true' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :auto, value: { 'text' => 'Auto' })
        component = described_class.new(market_attribute_response: response)

        expect(component.auto?).to be true
      end
    end

    context 'with manual source' do
      it 'returns false' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response)

        expect(component.auto?).to be false
      end
    end
  end

  describe '#manual_after_api_failure?' do
    context 'with manual_after_api_failure source' do
      it 'returns true' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual_after_api_failure, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response)

        expect(component.manual_after_api_failure?).to be true
      end
    end

    context 'with manual source' do
      it 'returns false' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response)

        expect(component.manual_after_api_failure?).to be false
      end
    end
  end

  describe '#show_value?' do
    context 'with manual source' do
      it 'returns true regardless of context' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual, value: { 'text' => 'Test' })
        component_web = described_class.new(market_attribute_response: response, context: :web)
        component_buyer = described_class.new(market_attribute_response: response, context: :buyer)

        expect(component_web.show_value?).to be true
        expect(component_buyer.show_value?).to be true
      end
    end

    context 'with auto source and web context' do
      it 'returns false' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :auto, value: { 'text' => 'Auto' })
        component = described_class.new(market_attribute_response: response, context: :web)

        expect(component.show_value?).to be false
      end
    end

    context 'with auto source and pdf context' do
      it 'returns false' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :auto, value: { 'text' => 'Auto' })
        component = described_class.new(market_attribute_response: response, context: :pdf)

        expect(component.show_value?).to be false
      end
    end

    context 'with auto source and buyer context' do
      it 'returns true' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :auto, value: { 'text' => 'Auto' })
        component = described_class.new(market_attribute_response: response, context: :buyer)

        expect(component.show_value?).to be true
      end
    end
  end

  describe '#field_label' do
    it 'returns DB value when candidate_name is present' do
      market_attribute.update!(candidate_name: 'DB Label')
      response = create(:market_attribute_response_text_input, market_attribute:, value: { 'text' => 'Test' })
      component = described_class.new(market_attribute_response: response)

      expect(component.field_label).to eq('DB Label')
    end

    it 'falls back to humanized key when candidate_name is blank' do
      response = create(:market_attribute_response_text_input, market_attribute:, value: { 'text' => 'Test' })
      component = described_class.new(market_attribute_response: response)

      expect(component.field_label).to eq('Test field')
    end
  end

  describe '#field_description' do
    it 'returns DB value when candidate_description is present' do
      market_attribute.update!(candidate_description: 'DB Description')
      response = create(:market_attribute_response_text_input, market_attribute:, value: { 'text' => 'Test' })
      component = described_class.new(market_attribute_response: response)

      expect(component.field_description).to eq('DB Description')
    end

    it 'returns nil when candidate_description is blank' do
      response = create(:market_attribute_response_text_input, market_attribute:, value: { 'text' => 'Test' })
      component = described_class.new(market_attribute_response: response)

      expect(component.field_description).to be_nil
    end
  end

  describe '#market_attribute' do
    it 'returns the market attribute from the response' do
      response = create(:market_attribute_response_text_input, market_attribute:, value: { 'text' => 'Test' })
      component = described_class.new(market_attribute_response: response)

      expect(component.market_attribute).to eq(market_attribute)
    end
  end

  describe '#auto_filled_message' do
    it 'returns i18n translation' do
      response = create(:market_attribute_response_text_input, market_attribute:, value: { 'text' => 'Test' })
      component = described_class.new(market_attribute_response: response)

      allow(I18n).to receive(:t).with('candidate.market_applications.auto_filled_message')
        .and_return('Automatically filled')

      expect(component.auto_filled_message).to eq('Automatically filled')
    end
  end
end
