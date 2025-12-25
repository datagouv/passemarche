# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::RealisationsLivraisonsComponent, type: :component do
  let(:market_attribute) { create(:market_attribute, :realisations_livraisons, key: 'test_realisations') }

  let(:complete_value) do
    {
      'items' => {
        '1702000000' => {
          'resume' => 'Construction batiment',
          'date_debut' => '2022-01-01',
          'date_fin' => '2022-12-31',
          'montant' => 500_000,
          'description' => 'Description detaillee du projet'
        },
        '1702000001' => {
          'resume' => 'Renovation facade',
          'date_debut' => '2023-06-01',
          'date_fin' => '2023-08-31',
          'montant' => 150_000,
          'description' => 'Travaux de renovation'
        }
      }
    }
  end

  let(:single_item_value) do
    {
      'items' => {
        '1702000000' => {
          'resume' => 'Single project',
          'montant' => 100_000
        }
      }
    }
  end

  describe '#data?' do
    context 'with data' do
      it 'returns true' do
        response = create(:market_attribute_response_realisations_livraisons,
          market_attribute:,
          value: complete_value)
        component = described_class.new(market_attribute_response: response)

        expect(component.data?).to be true
      end
    end

    context 'with empty value' do
      it 'returns false' do
        response = create(:market_attribute_response_realisations_livraisons,
          market_attribute:,
          value: nil)
        component = described_class.new(market_attribute_response: response)

        expect(component.data?).to be false
      end
    end

    context 'with empty items' do
      it 'returns false' do
        response = create(:market_attribute_response_realisations_livraisons,
          market_attribute:,
          value: { 'items' => {} })
        component = described_class.new(market_attribute_response: response)

        expect(component.data?).to be false
      end
    end
  end

  describe '#realisations_with_data' do
    it 'returns only items with data' do
      response = create(:market_attribute_response_realisations_livraisons,
        market_attribute:,
        value: complete_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.realisations_with_data.size).to eq(2)
    end

    it 'excludes empty items' do
      value_with_empty = {
        'items' => {
          '1702000000' => { 'resume' => 'Valid item', 'montant' => 1000 },
          '1702000001' => { 'resume' => '', 'montant' => nil }
        }
      }
      response = create(:market_attribute_response_realisations_livraisons,
        market_attribute:,
        value: value_with_empty)
      component = described_class.new(market_attribute_response: response)

      expect(component.realisations_with_data.size).to eq(1)
    end
  end

  describe '#realisation_has_data?' do
    it 'returns true for item with resume' do
      response = create(:market_attribute_response_realisations_livraisons,
        market_attribute:,
        value: single_item_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.realisation_has_data?({ 'resume' => 'Test' })).to be true
    end

    it 'returns false for empty hash' do
      response = create(:market_attribute_response_realisations_livraisons,
        market_attribute:,
        value: single_item_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.realisation_has_data?({})).to be false
    end

    it 'returns false for nil' do
      response = create(:market_attribute_response_realisations_livraisons,
        market_attribute:,
        value: single_item_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.realisation_has_data?(nil)).to be false
    end
  end

  describe '#formatted_date' do
    let(:response) do
      create(:market_attribute_response_realisations_livraisons,
        market_attribute:,
        value: single_item_value)
    end
    let(:component) { described_class.new(market_attribute_response: response) }

    it 'formats valid date' do
      result = component.formatted_date('2022-01-15')

      expect(result).to include('janvier')
      expect(result).to include('2022')
    end

    it 'returns nil for blank date' do
      expect(component.formatted_date('')).to be_nil
      expect(component.formatted_date(nil)).to be_nil
    end

    it 'returns original string for invalid date' do
      expect(component.formatted_date('invalid')).to eq('invalid')
    end
  end

  describe '#formatted_montant' do
    let(:response) do
      create(:market_attribute_response_realisations_livraisons,
        market_attribute:,
        value: single_item_value)
    end
    let(:component) { described_class.new(market_attribute_response: response) }

    it 'formats large amount with thousands separator' do
      result = component.formatted_montant(500_000)

      expect(result).to include('500')
      expect(result).to include('000')
    end

    it 'returns nil for blank montant' do
      expect(component.formatted_montant('')).to be_nil
      expect(component.formatted_montant(nil)).to be_nil
    end
  end

  describe 'form mode' do
    let(:form) { double('FormBuilder') }
    let(:response_form) { double('ResponseFormBuilder') }

    context 'with manual source' do
      it 'renders nested form with add button' do
        response = create(:market_attribute_response_realisations_livraisons,
          market_attribute:,
          source: :manual,
          value: single_item_value)
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:text_field).and_return('<input type="text">'.html_safe)
        allow(response_form).to receive(:text_area).and_return('<textarea></textarea>'.html_safe)
        allow(response_form).to receive(:label).and_return('<label></label>'.html_safe)
        allow(response_form).to receive(:file_field).and_return('<input type="file">'.html_safe)
        allow(response_form).to receive(:object).and_return(response)

        render_inline(component)

        expect(page).to have_css('[data-controller="nested-form"]')
        expect(page).to have_button('Ajouter une réalisation')
      end
    end

    context 'with auto source' do
      it 'renders auto-filled message' do
        response = create(:market_attribute_response_realisations_livraisons,
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
      it 'shows realisation cards' do
        response = create(:market_attribute_response_realisations_livraisons,
          market_attribute:,
          source: :manual,
          value: complete_value)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).to have_css('div.fr-card', count: 2)
        expect(page).to have_text('Réalisation 1')
        expect(page).to have_text('Réalisation 2')
        expect(page).to have_text('Construction batiment')
      end
    end

    context 'with montant display' do
      it 'shows formatted montant with EUR' do
        response = create(:market_attribute_response_realisations_livraisons,
          market_attribute:,
          source: :manual,
          value: complete_value)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('€')
      end
    end

    context 'without data' do
      it 'shows no data message' do
        response = create(:market_attribute_response_realisations_livraisons,
          market_attribute:,
          source: :manual,
          value: nil)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('Aucune réalisation renseignée')
      end
    end

    context 'with auto source and web context' do
      it 'does not show values' do
        response = create(:market_attribute_response_realisations_livraisons,
          market_attribute:,
          source: :auto,
          value: complete_value)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).not_to have_text('Construction batiment')
      end
    end

    context 'with auto source and buyer context' do
      it 'shows values' do
        response = create(:market_attribute_response_realisations_livraisons,
          market_attribute:,
          source: :auto,
          value: complete_value)
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_text('Construction batiment')
      end
    end
  end

  describe '#errors?' do
    it 'returns true when value errors present' do
      response = build_stubbed(:market_attribute_response_realisations_livraisons, market_attribute:)
      response.errors.add(:value, 'Error')
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be true
    end

    it 'returns false when no errors' do
      response = create(:market_attribute_response_realisations_livraisons,
        market_attribute:,
        value: complete_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be false
    end
  end
end
