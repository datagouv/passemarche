# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::CapaciteEconomiqueFinanciereChiffreAffairesGlobalAnnuelComponent, type: :component do
  let(:market_attribute) { create(:market_attribute, :chiffre_affaires, :mandatory, key: 'test_chiffre_affaires') }

  let(:complete_value) do
    {
      'year_1' => { 'turnover' => 500_000, 'market_percentage' => 75, 'fiscal_year_end' => '2023-12-31' },
      'year_2' => { 'turnover' => 450_000, 'market_percentage' => 80, 'fiscal_year_end' => '2022-12-31' },
      'year_3' => { 'turnover' => 400_000, 'market_percentage' => 70, 'fiscal_year_end' => '2021-12-31' }
    }
  end

  let(:partial_value) do
    {
      'year_1' => { 'turnover' => 500_000, 'market_percentage' => 75, 'fiscal_year_end' => '2023-12-31' }
    }
  end

  let(:api_value) do
    {
      'year_1' => { 'turnover' => 500_000, 'fiscal_year_end' => '2023-12-31' },
      'year_2' => { 'turnover' => 450_000, 'fiscal_year_end' => '2022-12-31' },
      '_api_fields' => {
        'year_1' => %w[turnover fiscal_year_end],
        'year_2' => %w[turnover fiscal_year_end]
      }
    }
  end

  describe '#data?' do
    context 'with complete data' do
      it 'returns true' do
        response = create(:market_attribute_response_chiffre_affaires, market_attribute:, value: complete_value)
        component = described_class.new(market_attribute_response: response)

        expect(component.data?).to be true
      end
    end

    context 'with empty value' do
      it 'returns false' do
        response = create(:market_attribute_response_chiffre_affaires, market_attribute:, value: nil)
        component = described_class.new(market_attribute_response: response)

        expect(component.data?).to be false
      end
    end
  end

  describe '#api_data?' do
    context 'with auto source and api fields' do
      it 'returns true' do
        response = create(:market_attribute_response_chiffre_affaires, market_attribute:, source: :auto, value: api_value)
        component = described_class.new(market_attribute_response: response)

        expect(component.api_data?).to be true
      end
    end

    context 'with manual source' do
      it 'returns false' do
        response = create(:market_attribute_response_chiffre_affaires, market_attribute:, source: :manual, value: complete_value)
        component = described_class.new(market_attribute_response: response)

        expect(component.api_data?).to be false
      end
    end
  end

  describe '#field_from_api?' do
    context 'when field is from API' do
      it 'returns true' do
        response = create(:market_attribute_response_chiffre_affaires, market_attribute:, source: :auto, value: api_value)
        component = described_class.new(market_attribute_response: response)

        expect(component.field_from_api?('year_1', 'turnover')).to be true
      end
    end

    context 'when field is not from API' do
      it 'returns false' do
        response = create(:market_attribute_response_chiffre_affaires, market_attribute:, source: :auto, value: api_value)
        component = described_class.new(market_attribute_response: response)

        expect(component.field_from_api?('year_1', 'market_percentage')).to be false
      end
    end
  end

  describe '#formatted_turnover' do
    it 'formats turnover with delimiter and euro symbol' do
      response = create(:market_attribute_response_chiffre_affaires, market_attribute:, value: complete_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.formatted_turnover('year_1')).to eq('500 000 €')
    end

    it 'returns nil for missing turnover' do
      response = create(:market_attribute_response_chiffre_affaires, market_attribute:, value: { 'year_1' => {} })
      component = described_class.new(market_attribute_response: response)

      expect(component.formatted_turnover('year_1')).to be_nil
    end
  end

  describe '#formatted_fiscal_year_end' do
    it 'formats date in French format' do
      response = create(:market_attribute_response_chiffre_affaires, market_attribute:, value: complete_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.formatted_fiscal_year_end('year_1')).to eq('31/12/2023')
    end
  end

  describe 'form mode' do
    let(:form) { double('FormBuilder') }
    let(:response_form) { double('ResponseFormBuilder') }

    context 'with manual source' do
      it 'renders table with input fields' do
        response = create(:market_attribute_response_chiffre_affaires, market_attribute:, source: :manual, value: complete_value)
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:text_field).and_return('<input>'.html_safe)
        allow(response_form).to receive(:object).and_return(response)

        render_inline(component)

        expect(page).to have_css('table')
        expect(page).to have_css('th', count: 4)
      end
    end

    context 'with auto source and api data' do
      it 'renders notice message' do
        response = create(:market_attribute_response_chiffre_affaires, market_attribute:, source: :auto, value: api_value)
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:text_field).and_return('<input>'.html_safe)
        allow(response_form).to receive(:object).and_return(response)

        render_inline(component)

        expect(page).to have_css('table')
      end
    end
  end

  describe 'display mode' do
    context 'with data and web context' do
      it 'shows field label and table' do
        response = create(:market_attribute_response_chiffre_affaires, market_attribute:, source: :manual, value: complete_value)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).to have_css('table')
        expect(page).to have_text('500 000 €')
      end
    end

    context 'without data' do
      it 'shows not provided message' do
        response = create(:market_attribute_response_chiffre_affaires, market_attribute:, source: :manual, value: nil)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('Non renseigné')
      end
    end

    context 'with auto source and web context' do
      it 'shows source badge in place of turnover' do
        response = create(:market_attribute_response_chiffre_affaires, market_attribute:, source: :auto, value: api_value)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('span.fr-badge')
      end
    end

    context 'with auto source and buyer context' do
      it 'shows actual values with source badge' do
        response = create(:market_attribute_response_chiffre_affaires, market_attribute:, source: :auto, value: api_value)
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_text('500 000 €')
      end
    end

    context 'with pdf context' do
      it 'uses ca-table class' do
        response = create(:market_attribute_response_chiffre_affaires, market_attribute:, source: :manual, value: complete_value)
        component = described_class.new(market_attribute_response: response, context: :pdf)

        render_inline(component)

        expect(page).to have_css('table.ca-table')
      end
    end
  end

  describe '#errors?' do
    it 'returns true when value errors present' do
      response = build_stubbed(:market_attribute_response_chiffre_affaires, market_attribute:)
      response.errors.add(:value, 'Error')
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be true
    end

    it 'returns true when year errors present' do
      response = build_stubbed(:market_attribute_response_chiffre_affaires, market_attribute:)
      response.errors.add(:year_1, 'Error')
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be true
    end

    it 'returns false when no errors' do
      response = create(:market_attribute_response_chiffre_affaires, market_attribute:, value: complete_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be false
    end
  end
end
