# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::RadioWithFileAndTextComponent, type: :component do
  let(:market_attribute) { create(:market_attribute, :radio_with_file_and_text, :mandatory, key: 'test_radio_with_file') }

  describe '#radio_yes? and #radio_no?' do
    context 'when radio_choice is yes' do
      it 'returns true for radio_yes?' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, value: { 'radio_choice' => 'yes' })
        component = described_class.new(market_attribute_response: response)

        expect(component.radio_yes?).to be true
        expect(component.radio_no?).to be false
      end
    end

    context 'when radio_choice is no' do
      it 'returns true for radio_no?' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, value: { 'radio_choice' => 'no' })
        component = described_class.new(market_attribute_response: response)

        expect(component.radio_yes?).to be false
        expect(component.radio_no?).to be true
      end
    end
  end

  describe '#text?' do
    context 'with text present' do
      it 'returns true' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:,
          value: { 'radio_choice' => 'yes', 'text' => 'Some text' })
        component = described_class.new(market_attribute_response: response)

        expect(component.text?).to be true
      end
    end

    context 'with text blank' do
      it 'returns false' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, value: { 'radio_choice' => 'yes', 'text' => '' })
        component = described_class.new(market_attribute_response: response)

        expect(component.text?).to be false
      end
    end
  end

  describe '#documents_attached?' do
    context 'with documents attached' do
      it 'returns true' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, value: { 'radio_choice' => 'yes' })
        response.documents.attach(io: StringIO.new('test'), filename: 'test.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response)

        expect(component.documents_attached?).to be true
      end
    end

    context 'without documents attached' do
      it 'returns false' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, value: { 'radio_choice' => 'no' })
        component = described_class.new(market_attribute_response: response)

        expect(component.documents_attached?).to be false
      end
    end
  end

  describe '#conditional_content_hidden?' do
    it 'returns true when radio_no?' do
      response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, value: { 'radio_choice' => 'no' })
      component = described_class.new(market_attribute_response: response)

      expect(component.conditional_content_hidden?).to be true
    end

    it 'returns false when radio_yes?' do
      response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, value: { 'radio_choice' => 'yes' })
      component = described_class.new(market_attribute_response: response)

      expect(component.conditional_content_hidden?).to be false
    end
  end

  describe 'form mode' do
    let(:form) { double('FormBuilder') }
    let(:response_form) { double('ResponseFormBuilder') }

    context 'with manual source' do
      it 'renders radio buttons' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, source: :manual, value: { 'radio_choice' => 'no' })
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)
        allow(response_form).to receive(:radio_button).and_return('<input type="radio">'.html_safe)
        allow(response_form).to receive(:label).and_return('<label>'.html_safe)
        allow(response_form).to receive(:text_area).and_return('<textarea>'.html_safe)
        allow(response_form).to receive(:file_field).and_return('<input type="file">'.html_safe)
        allow(response_form).to receive(:object).and_return(response)

        render_inline(component)

        expect(page).to have_css('div.fr-radio-group')
        expect(page).to have_css('[data-controller="conditional-fields"]')
      end
    end

    context 'with auto source' do
      it 'renders auto-filled message for non-ESS fields' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, source: :auto, value: { 'radio_choice' => 'yes' })
        component = described_class.new(market_attribute_response: response, form:)

        allow(form).to receive(:fields_for).and_yield(response_form)
        allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)

        render_inline(component)

        expect(page).to have_css('p.fr-text--sm.fr-text--mention-grey')
      end

      context 'with ESS market attribute' do
        let(:ess_attribute) do
          create(:market_attribute, :radio_with_file_and_text, :mandatory,
            key: 'capacites_techniques_professionnelles_certificats_ess',
            api_name: 'insee',
            api_key: 'ess')
        end

        it 'renders EssComponent instead of auto-filled message' do
          response = create(:market_attribute_response_radio_with_file_and_text, market_attribute: ess_attribute, source: :auto, value: { 'radio_choice' => 'yes' })
          component = described_class.new(market_attribute_response: response, form:)

          allow(form).to receive(:fields_for).and_yield(response_form)
          allow(response_form).to receive(:hidden_field).and_return('<input type="hidden">'.html_safe)

          render_inline(component)

          expect(page).to have_text("L'entreprise est une ESS :")
          expect(page).to have_text('Oui')
          expect(page).not_to have_css('p.fr-text--sm.fr-text--mention-grey')
        end
      end
    end
  end

  describe 'display mode' do
    context 'with manual source and web context' do
      it 'shows field label' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, source: :manual, value: { 'radio_choice' => 'no' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).to have_css('strong')
      end

      it 'shows Non badge when radio_no?' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, source: :manual, value: { 'radio_choice' => 'no' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.fr-badge', text: 'Non')
      end

      it 'shows Oui badge when radio_yes?' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, source: :manual, value: { 'radio_choice' => 'yes' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.fr-badge.fr-badge--success', text: 'Oui')
      end

      it 'shows text when present and radio_yes?' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, source: :manual,
          value: { 'radio_choice' => 'yes', 'text' => 'My response' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('Réponse :')
        expect(page).to have_text('My response')
      end

      it 'shows documents when attached and radio_yes?' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, source: :manual, value: { 'radio_choice' => 'yes' })
        response.documents.attach(io: StringIO.new('test'), filename: 'test.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('Documents joints :')
        expect(page).to have_text('test.pdf')
      end

      it 'shows no info message when yes but no text and no documents' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, source: :manual, value: { 'radio_choice' => 'yes' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('Aucune information complémentaire fournie')
      end

      it 'shows Non renseigné badge when radio_choice is nil' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, source: :manual_after_api_failure, value: {})
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.fr-badge.fr-badge--warning', text: 'Non renseigné')
      end
    end

    context 'with auto source and web context' do
      it 'shows field label but hides value' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, source: :auto, value: { 'radio_choice' => 'yes' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.field-layout-container')
        expect(page).not_to have_css('div.fr-badge', text: 'Oui')
      end

      it 'renders source badge' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, source: :auto, value: { 'radio_choice' => 'yes' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('span.fr-badge.fr-badge--success')
      end
    end

    context 'with auto source and buyer context' do
      it 'shows radio choice and text for buyer' do
        response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, source: :auto,
          value: { 'radio_choice' => 'yes', 'text' => 'Buyer text' })
        response.documents.attach(io: StringIO.new('test'), filename: 'buyer.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_text('Buyer text')
        expect(page).to have_text('buyer.pdf')
      end
    end
  end

  describe '#ess_api_data?' do
    let(:ess_attribute) do
      create(:market_attribute, :radio_with_file_and_text, :mandatory,
        key: 'capacites_techniques_professionnelles_certificats_ess',
        api_name: 'insee',
        api_key: 'ess')
    end

    context 'with ESS market attribute and auto source' do
      it 'returns true' do
        response = create(:market_attribute_response_radio_with_file_and_text,
          market_attribute: ess_attribute, source: :auto, value: { 'radio_choice' => 'yes' })
        component = described_class.new(market_attribute_response: response)

        expect(component.ess_api_data?).to be true
      end
    end

    context 'with ESS market attribute and manual source' do
      it 'returns false' do
        response = create(:market_attribute_response_radio_with_file_and_text,
          market_attribute: ess_attribute, source: :manual, value: { 'radio_choice' => 'yes' })
        component = described_class.new(market_attribute_response: response)

        expect(component.ess_api_data?).to be false
      end
    end

    context 'with ESS market attribute and manual_after_api_failure source' do
      it 'returns false' do
        response = create(:market_attribute_response_radio_with_file_and_text,
          market_attribute: ess_attribute, source: :manual_after_api_failure, value: {})
        component = described_class.new(market_attribute_response: response)

        expect(component.ess_api_data?).to be false
      end
    end

    context 'with non-ESS market attribute' do
      it 'returns false' do
        response = create(:market_attribute_response_radio_with_file_and_text,
          market_attribute:, source: :auto, value: { 'radio_choice' => 'yes' })
        component = described_class.new(market_attribute_response: response)

        expect(component.ess_api_data?).to be false
      end
    end
  end

  describe 'display mode with ESS API data' do
    let(:ess_attribute) do
      create(:market_attribute, :radio_with_file_and_text, :mandatory,
        key: 'capacites_techniques_professionnelles_certificats_ess',
        api_name: 'insee',
        api_key: 'ess')
    end

    context 'with auto source (API data)' do
      it 'shows simplified EssComponent display' do
        response = create(:market_attribute_response_radio_with_file_and_text,
          market_attribute: ess_attribute, source: :auto, value: { 'radio_choice' => 'yes' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text("L'entreprise est une ESS :")
        expect(page).to have_text('Oui')
        expect(page).not_to have_css('div.fr-badge', text: 'Oui')
      end

      it 'shows EssComponent for buyer context too' do
        response = create(:market_attribute_response_radio_with_file_and_text,
          market_attribute: ess_attribute, source: :auto, value: { 'radio_choice' => 'no' })
        component = described_class.new(market_attribute_response: response, context: :buyer)

        render_inline(component)

        expect(page).to have_text("L'entreprise est une ESS :")
        expect(page).to have_text('Non')
      end
    end

    context 'with manual source (not API data)' do
      it 'shows standard display with badge for ESS manual entry' do
        response = create(:market_attribute_response_radio_with_file_and_text,
          market_attribute: ess_attribute, source: :manual, value: { 'radio_choice' => 'yes' })
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.fr-badge.fr-badge--success', text: 'Oui')
        expect(page).not_to have_text("L'entreprise est une ESS :")
      end
    end

    context 'with manual_after_api_failure source' do
      it 'shows standard display with text and files when provided' do
        response = create(:market_attribute_response_radio_with_file_and_text,
          market_attribute: ess_attribute,
          source: :manual_after_api_failure,
          value: { 'radio_choice' => 'yes', 'text' => 'Mon justificatif ESS' })
        response.documents.attach(io: StringIO.new('test'), filename: 'justificatif.pdf', content_type: 'application/pdf')
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_text('Mon justificatif ESS')
        expect(page).to have_text('justificatif.pdf')
        expect(page).to have_css('div.fr-badge.fr-badge--success', text: 'Oui')
      end

      it 'shows Non renseigné badge when radio_choice is nil' do
        response = create(:market_attribute_response_radio_with_file_and_text,
          market_attribute: ess_attribute, source: :manual_after_api_failure, value: {})
        component = described_class.new(market_attribute_response: response, context: :web)

        render_inline(component)

        expect(page).to have_css('div.fr-badge.fr-badge--warning', text: 'Non renseigné')
      end
    end
  end

  describe '#errors?' do
    it 'returns true when value errors present' do
      response = build_stubbed(:market_attribute_response_radio_with_file_and_text, market_attribute:)
      response.errors.add(:value, 'Error')
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be true
    end

    it 'returns true when text errors present' do
      response = build_stubbed(:market_attribute_response_radio_with_file_and_text, market_attribute:)
      response.errors.add(:text, 'Error')
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be true
    end

    it 'returns false when no errors' do
      response = create(:market_attribute_response_radio_with_file_and_text, market_attribute:, value: { 'radio_choice' => 'yes' })
      component = described_class.new(market_attribute_response: response)

      expect(component.errors?).to be false
    end
  end

  describe '#badge_class' do
    context 'with motifs_exclusion category' do
      let(:motifs_exclusion_attribute) do
        create(:market_attribute, :radio_with_file_and_text, :mandatory,
          key: 'motifs_exclusion_test', category_key: 'motifs_exclusion')
      end

      it 'returns error badge when radio_yes' do
        response = create(:market_attribute_response_radio_with_file_and_text,
          market_attribute: motifs_exclusion_attribute, value: { 'radio_choice' => 'yes' })
        component = described_class.new(market_attribute_response: response)

        expect(component.badge_class).to eq('fr-badge fr-badge--error fr-badge--sm')
      end

      it 'returns success badge when radio_no' do
        response = create(:market_attribute_response_radio_with_file_and_text,
          market_attribute: motifs_exclusion_attribute, value: { 'radio_choice' => 'no' })
        component = described_class.new(market_attribute_response: response)

        expect(component.badge_class).to eq('fr-badge fr-badge--success fr-badge--sm')
      end

      it 'returns warning badge when radio_choice is nil' do
        response = create(:market_attribute_response_radio_with_file_and_text,
          market_attribute: motifs_exclusion_attribute, source: :manual_after_api_failure, value: {})
        component = described_class.new(market_attribute_response: response)

        expect(component.badge_class).to eq('fr-badge fr-badge--warning fr-badge--sm')
      end
    end

    context 'with non-motifs_exclusion category' do
      it 'returns success badge when radio_yes' do
        response = create(:market_attribute_response_radio_with_file_and_text,
          market_attribute:, value: { 'radio_choice' => 'yes' })
        component = described_class.new(market_attribute_response: response)

        expect(component.badge_class).to eq('fr-badge fr-badge--success fr-badge--sm')
      end

      it 'returns neutral badge when radio_no' do
        response = create(:market_attribute_response_radio_with_file_and_text,
          market_attribute:, value: { 'radio_choice' => 'no' })
        component = described_class.new(market_attribute_response: response)

        expect(component.badge_class).to eq('fr-badge fr-badge--sm')
      end

      it 'returns warning badge when radio_choice is nil' do
        response = create(:market_attribute_response_radio_with_file_and_text,
          market_attribute:, source: :manual_after_api_failure, value: {})
        component = described_class.new(market_attribute_response: response)

        expect(component.badge_class).to eq('fr-badge fr-badge--warning fr-badge--sm')
      end
    end
  end

  describe '#motifs_exclusion_category?' do
    context 'with motifs_exclusion category' do
      let(:motifs_exclusion_attribute) do
        create(:market_attribute, :radio_with_file_and_text, :mandatory,
          key: 'motifs_exclusion_test', category_key: 'motifs_exclusion')
      end

      it 'returns true' do
        response = create(:market_attribute_response_radio_with_file_and_text,
          market_attribute: motifs_exclusion_attribute, value: { 'radio_choice' => 'yes' })
        component = described_class.new(market_attribute_response: response)

        expect(component.motifs_exclusion_category?).to be true
      end
    end

    context 'with other category' do
      it 'returns false' do
        response = create(:market_attribute_response_radio_with_file_and_text,
          market_attribute:, value: { 'radio_choice' => 'yes' })
        component = described_class.new(market_attribute_response: response)

        expect(component.motifs_exclusion_category?).to be false
      end
    end
  end

  describe '#badge_label' do
    it 'returns Oui when radio_yes' do
      response = create(:market_attribute_response_radio_with_file_and_text,
        market_attribute:, value: { 'radio_choice' => 'yes' })
      component = described_class.new(market_attribute_response: response)

      expect(component.badge_label).to eq('Oui')
    end

    it 'returns Non when radio_no' do
      response = create(:market_attribute_response_radio_with_file_and_text,
        market_attribute:, value: { 'radio_choice' => 'no' })
      component = described_class.new(market_attribute_response: response)

      expect(component.badge_label).to eq('Non')
    end

    it 'returns Non renseigné when radio_choice is nil' do
      response = create(:market_attribute_response_radio_with_file_and_text,
        market_attribute:, source: :manual_after_api_failure, value: {})
      component = described_class.new(market_attribute_response: response)

      expect(component.badge_label).to eq('Non renseigné')
    end
  end
end
