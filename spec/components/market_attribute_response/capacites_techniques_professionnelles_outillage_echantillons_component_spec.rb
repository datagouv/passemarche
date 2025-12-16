# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::CapacitesTechniquesProfessionnellesOutillageEchantillonsComponent,
  type: :component do
  let(:market_attribute) { create(:market_attribute, :outillage_echantillons, key: 'test_echantillons') }

  let(:complete_value) do
    {
      'items' => {
        '1702000000' => { 'description' => 'Sample 1 description' },
        '1702000001' => { 'description' => 'Sample 2 description' }
      }
    }
  end

  let(:single_item_value) do
    {
      'items' => {
        '1702000000' => { 'description' => 'Single sample description' }
      }
    }
  end

  describe '#data?' do
    context 'with data' do
      it 'returns true' do
        response = create(:market_attribute_response_outillage_echantillons,
          market_attribute:,
          value: complete_value)
        component = described_class.new(market_attribute_response: response)

        expect(component.data?).to be true
      end
    end

    context 'with empty value' do
      it 'returns false' do
        response = create(:market_attribute_response_outillage_echantillons,
          market_attribute:,
          value: nil)
        component = described_class.new(market_attribute_response: response)

        expect(component.data?).to be false
      end
    end

    context 'with empty items' do
      it 'returns false' do
        response = create(:market_attribute_response_outillage_echantillons,
          market_attribute:,
          value: { 'items' => {} })
        component = described_class.new(market_attribute_response: response)

        expect(component.data?).to be false
      end
    end
  end

  describe '#echantillons_with_data' do
    it 'returns only items with data' do
      response = create(:market_attribute_response_outillage_echantillons,
        market_attribute:,
        value: complete_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.echantillons_with_data.size).to eq(2)
    end

    it 'excludes empty items' do
      value_with_empty = {
        'items' => {
          '1702000000' => { 'description' => 'Valid item' },
          '1702000001' => { 'description' => '' }
        }
      }
      response = create(:market_attribute_response_outillage_echantillons,
        market_attribute:,
        value: value_with_empty)
      component = described_class.new(market_attribute_response: response)

      expect(component.echantillons_with_data.size).to eq(1)
    end
  end

  describe '#echantillon_has_data?' do
    it 'returns true for item with description' do
      response = create(:market_attribute_response_outillage_echantillons,
        market_attribute:,
        value: single_item_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.echantillon_has_data?({ 'description' => 'Test' })).to be true
    end

    it 'returns false for empty hash' do
      response = create(:market_attribute_response_outillage_echantillons,
        market_attribute:,
        value: single_item_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.echantillon_has_data?({})).to be false
    end

    it 'returns false for nil' do
      response = create(:market_attribute_response_outillage_echantillons,
        market_attribute:,
        value: single_item_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.echantillon_has_data?(nil)).to be false
    end
  end

  describe 'form mode' do
    let(:form) { double('FormBuilder') }
    let(:response_form) { double('ResponseFormBuilder') }

    context 'with manual source' do
      it 'renders nested form with add button' do
        response = create(:market_attribute_response_outillage_echantillons,
          market_attribute:,
          source: :manual,
          value: single_item_value)
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:text_area).and_return('<textarea></textarea>'.html_safe)
        allow(response_form).to receive(:label).and_return('<label></label>'.html_safe)
        allow(response_form).to receive(:file_field).and_return('<input type="file">'.html_safe)
        allow(response_form).to receive(:object).and_return(response)

        render_inline(component)

        expect(page).to have_css('[data-controller="nested-form"]')
        expect(page).to have_button('Ajouter un echantillon')
      end
    end

    context 'with auto source' do
      it 'renders auto-filled message' do
        response = create(:market_attribute_response_outillage_echantillons,
          market_attribute:,
          source: :auto,
          value: complete_value)
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)

        render_inline(component)

        expect(page).to have_css('span.fr-badge')
      end
    end
  end

  describe 'display mode' do
    context 'with data and web context' do
      it 'shows echantillon cards' do
        response = create(:market_attribute_response_outillage_echantillons,
          market_attribute:,
          source: :manual,
          value: complete_value)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).to have_css('div.fr-card', count: 2)
        expect(page).to have_text('Echantillon 1')
        expect(page).to have_text('Echantillon 2')
        expect(page).to have_text('Sample 1 description')
      end
    end

    context 'without data' do
      it 'shows no data message' do
        response = create(:market_attribute_response_outillage_echantillons,
          market_attribute:,
          source: :manual,
          value: nil)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('Aucun echantillon renseigne')
      end
    end

    context 'with auto source and web context' do
      it 'does not show values' do
        response = create(:market_attribute_response_outillage_echantillons,
          market_attribute:,
          source: :auto,
          value: complete_value)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).not_to have_text('Sample 1 description')
      end
    end

    context 'with auto source and buyer context' do
      it 'shows values' do
        response = create(:market_attribute_response_outillage_echantillons,
          market_attribute:,
          source: :auto,
          value: complete_value)
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_text('Sample 1 description')
      end
    end
  end

  describe '#errors?' do
    it 'returns true when value errors present' do
      response = build_stubbed(:market_attribute_response_outillage_echantillons, market_attribute:)
      response.errors.add(:value, 'Error')
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be true
    end

    it 'returns false when no errors' do
      response = create(:market_attribute_response_outillage_echantillons,
        market_attribute:,
        value: complete_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be false
    end
  end
end
