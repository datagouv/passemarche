# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SourceBadgeComponent, type: :component do
  let(:market_attribute) { create(:market_attribute, :text_input) }

  describe '#render?' do
    context 'with auto source' do
      it 'returns true' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :auto, value: { 'text' => 'Auto' })
        component = described_class.new(market_attribute_response: response)

        expect(component.render?).to be true
      end
    end

    context 'with manual_after_api_failure source' do
      it 'returns true' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual_after_api_failure, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response)

        expect(component.render?).to be true
      end
    end

    context 'with manual source' do
      it 'returns false' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response)

        expect(component.render?).to be false
      end
    end

    context 'with explicit source parameter' do
      it 'returns true when source is :auto' do
        component = described_class.new(source: :auto)

        expect(component.render?).to be true
      end

      it 'returns true when source is :manual_after_api_failure' do
        component = described_class.new(source: :manual_after_api_failure)

        expect(component.render?).to be true
      end

      it 'returns false when source is nil' do
        component = described_class.new(source: nil)

        expect(component.render?).to be false
      end

      it 'returns false without any parameters' do
        component = described_class.new

        expect(component.render?).to be false
      end
    end
  end

  describe '#badge_text' do
    context 'when auto source' do
      it 'returns i18n translation for data_from_api' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :auto, value: { 'text' => 'Auto' })
        component = described_class.new(market_attribute_response: response)

        allow(I18n).to receive(:t).with('candidate.market_applications.badges.data_from_api')
          .and_return('Données API')

        expect(component.badge_text).to eq('Données API')
      end
    end

    context 'when manual_after_api_failure source' do
      it 'returns i18n translation for declared_on_honor' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual_after_api_failure, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response)

        allow(I18n).to receive(:t).with('candidate.market_applications.badges.declared_on_honor')
          .and_return('Déclaré sur l\'honneur')

        expect(component.badge_text).to eq('Déclaré sur l\'honneur')
      end
    end

    context 'with explicit source parameter' do
      it 'returns i18n translation for data_from_api when source is :auto' do
        component = described_class.new(source: :auto)

        allow(I18n).to receive(:t).with('candidate.market_applications.badges.data_from_api')
          .and_return('Données API')

        expect(component.badge_text).to eq('Données API')
      end

      it 'returns i18n translation for declared_on_honor when source is :manual_after_api_failure' do
        component = described_class.new(source: :manual_after_api_failure)

        allow(I18n).to receive(:t).with('candidate.market_applications.badges.declared_on_honor')
          .and_return('Déclaré sur l\'honneur')

        expect(component.badge_text).to eq('Déclaré sur l\'honneur')
      end
    end
  end

  describe '#badge_css_class' do
    context 'when auto source' do
      it 'returns success badge classes' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :auto, value: { 'text' => 'Auto' })
        component = described_class.new(market_attribute_response: response)

        expect(component.badge_css_class).to eq('fr-badge fr-badge--success fr-badge--sm')
      end
    end

    context 'when manual_after_api_failure source' do
      it 'returns info badge classes' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual_after_api_failure, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response)

        expect(component.badge_css_class).to eq('fr-badge fr-badge--info fr-badge--sm')
      end
    end

    context 'with explicit source parameter' do
      it 'returns success badge classes when source is :auto' do
        component = described_class.new(source: :auto)

        expect(component.badge_css_class).to eq('fr-badge fr-badge--success fr-badge--sm')
      end

      it 'returns info badge classes when source is :manual_after_api_failure' do
        component = described_class.new(source: :manual_after_api_failure)

        expect(component.badge_css_class).to eq('fr-badge fr-badge--info fr-badge--sm')
      end
    end
  end

  describe 'rendered output' do
    context 'when auto source' do
      it 'renders badge with success class and text' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :auto, value: { 'text' => 'Auto' })
        component = described_class.new(market_attribute_response: response)

        render_inline(component)

        expect(page).to have_css('span.fr-badge.fr-badge--success.fr-badge--sm')
      end

      it 'does not include line break' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :auto, value: { 'text' => 'Auto' })
        component = described_class.new(market_attribute_response: response)

        render_inline(component)

        expect(rendered_content).not_to include('<br>')
      end
    end

    context 'when manual_after_api_failure source' do
      it 'renders badge with info class' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual_after_api_failure, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response)

        render_inline(component)

        expect(page).to have_css('span.fr-badge.fr-badge--info.fr-badge--sm')
      end
    end

    context 'when manual source' do
      it 'does not render anything' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response)

        render_inline(component)

        expect(rendered_content).to be_blank
      end
    end

    context 'with explicit source parameter' do
      it 'renders badge with success class when source is :auto' do
        component = described_class.new(source: :auto)

        render_inline(component)

        expect(page).to have_css('span.fr-badge.fr-badge--success.fr-badge--sm')
      end

      it 'renders badge with info class when source is :manual_after_api_failure' do
        component = described_class.new(source: :manual_after_api_failure)

        render_inline(component)

        expect(page).to have_css('span.fr-badge.fr-badge--info.fr-badge--sm')
      end

      it 'does not render anything without parameters' do
        component = described_class.new

        render_inline(component)

        expect(rendered_content).to be_blank
      end
    end
  end
end
