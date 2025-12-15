# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::CapaciteEconomiqueFinanciereEffectifsMoyensAnnuelsComponent, type: :component do
  let(:market_attribute) { create(:market_attribute, :effectifs_moyens_annuels, :mandatory, key: 'test_effectifs') }

  let(:complete_value) do
    {
      'year_1' => { 'year' => 2024, 'average_staff' => 30 },
      'year_2' => { 'year' => 2023, 'average_staff' => 32 },
      'year_3' => { 'year' => 2022, 'average_staff' => 35 }
    }
  end

  let(:partial_value) do
    {
      'year_1' => { 'year' => 2024, 'average_staff' => 30 }
    }
  end

  describe '#data?' do
    context 'with complete data' do
      it 'returns true' do
        response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, value: complete_value)
        component = described_class.new(market_attribute_response: response)

        expect(component.data?).to be true
      end
    end

    context 'with partial data' do
      it 'returns true' do
        response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, value: partial_value)
        component = described_class.new(market_attribute_response: response)

        expect(component.data?).to be true
      end
    end

    context 'with empty value' do
      it 'returns false' do
        response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, value: nil)
        component = described_class.new(market_attribute_response: response)

        expect(component.data?).to be false
      end
    end

    context 'with empty hash' do
      it 'returns false' do
        response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, value: {})
        component = described_class.new(market_attribute_response: response)

        expect(component.data?).to be false
      end
    end
  end

  describe '#year_data' do
    it 'returns data for a specific year' do
      response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, value: complete_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.year_data('year_1')).to eq({ 'year' => 2024, 'average_staff' => 30 })
    end

    it 'returns empty hash for missing year' do
      response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, value: partial_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.year_data('year_2')).to eq({})
    end
  end

  describe '#year_value' do
    it 'returns the year value' do
      response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, value: complete_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.year_value('year_1')).to eq(2024)
    end

    it 'returns nil for missing year' do
      response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, value: {})
      component = described_class.new(market_attribute_response: response)

      expect(component.year_value('year_1')).to be_nil
    end
  end

  describe '#average_staff_value' do
    it 'returns the average staff value' do
      response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, value: complete_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.average_staff_value('year_1')).to eq(30)
    end

    it 'returns nil for missing average_staff' do
      response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, value: {})
      component = described_class.new(market_attribute_response: response)

      expect(component.average_staff_value('year_1')).to be_nil
    end
  end

  describe '#year_label' do
    it 'returns the correct label for year_1' do
      response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, value: complete_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.year_label('year_1')).to eq('n-1')
    end

    it 'returns the correct label for year_2' do
      response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, value: complete_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.year_label('year_2')).to eq('n-2')
    end

    it 'returns the correct label for year_3' do
      response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, value: complete_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.year_label('year_3')).to eq('n-3')
    end
  end

  describe 'form mode' do
    let(:form) { double('FormBuilder') }
    let(:response_form) { double('ResponseFormBuilder') }

    context 'with manual source' do
      it 'renders form with input fields' do
        response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, source: :manual,
          value: complete_value)
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:text_field).and_return('<input>'.html_safe)
        allow(response_form).to receive(:object).and_return(response)

        render_inline(component)

        expect(page).to have_css('div.fr-input-group')
        expect(page).to have_text('Annee n-1')
        expect(page).to have_text('Effectif moyen')
      end
    end

    context 'with auto source' do
      it 'renders auto-filled message' do
        response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, source: :auto,
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
      it 'shows data for each year' do
        response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, source: :manual,
          value: complete_value)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).to have_text('Annee n-1')
        expect(page).to have_text('2024')
        expect(page).to have_text('30')
      end
    end

    context 'without data' do
      it 'shows not provided message' do
        response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, source: :manual,
          value: nil)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('Non renseigné')
      end
    end

    context 'with auto source and web context' do
      it 'does not show values (hidden)' do
        response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, source: :auto,
          value: complete_value)
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).not_to have_text('2024')
      end
    end

    context 'with auto source and buyer context' do
      it 'shows values' do
        response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, source: :auto,
          value: complete_value)
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_text('2024')
        expect(page).to have_text('30')
      end
    end

    context 'with pdf context' do
      it 'renders correctly' do
        response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, source: :manual,
          value: complete_value)
        component = described_class.new(market_attribute_response: response, context: :pdf)

        render_inline(component)

        expect(page).to have_text('2024')
        expect(page).to have_text('30')
      end
    end
  end

  describe '#errors?' do
    it 'returns true when value errors present' do
      response = build_stubbed(:market_attribute_response_effectifs_moyens_annuels, market_attribute:)
      response.errors.add(:value, 'Error')
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be true
    end

    it 'returns true when year errors present' do
      response = build_stubbed(:market_attribute_response_effectifs_moyens_annuels, market_attribute:)
      response.errors.add(:year_1, 'Error')
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be true
    end

    it 'returns false when no errors' do
      response = create(:market_attribute_response_effectifs_moyens_annuels, market_attribute:, value: complete_value)
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be false
    end
  end
end
