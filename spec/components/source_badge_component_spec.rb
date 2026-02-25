# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SourceBadgeComponent, type: :component do
  let(:market_attribute) { create(:market_attribute, :text_input) }

  describe '#render?' do
    context 'with auto source' do
      it 'returns true regardless of context' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :auto, value: { 'text' => 'Auto' })

        expect(described_class.new(market_attribute_response: response).render?).to be true
        expect(described_class.new(market_attribute_response: response, context: :buyer).render?).to be true
        expect(described_class.new(market_attribute_response: response, context: :web).render?).to be true
        expect(described_class.new(market_attribute_response: response, context: :pdf).render?).to be true
      end
    end

    context 'with manual_after_api_failure source' do
      it 'returns true only in buyer context' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual_after_api_failure, value: { 'text' => 'Test' })

        expect(described_class.new(market_attribute_response: response, context: :buyer).render?).to be true
        expect(described_class.new(market_attribute_response: response, context: :web).render?).to be false
        expect(described_class.new(market_attribute_response: response, context: :pdf).render?).to be false
        expect(described_class.new(market_attribute_response: response).render?).to be false
      end
    end

    context 'with manual source' do
      it 'returns true only in buyer context' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual, value: { 'text' => 'Test' })

        expect(described_class.new(market_attribute_response: response, context: :buyer).render?).to be true
        expect(described_class.new(market_attribute_response: response, context: :web).render?).to be false
        expect(described_class.new(market_attribute_response: response, context: :pdf).render?).to be false
        expect(described_class.new(market_attribute_response: response).render?).to be false
      end
    end

    context 'with explicit source parameter' do
      it 'returns true for :auto regardless of context' do
        expect(described_class.new(source: :auto).render?).to be true
        expect(described_class.new(source: :auto, context: :buyer).render?).to be true
        expect(described_class.new(source: :auto, context: :web).render?).to be true
      end

      it 'returns true for :manual_after_api_failure only in buyer context' do
        expect(described_class.new(source: :manual_after_api_failure, context: :buyer).render?).to be true
        expect(described_class.new(source: :manual_after_api_failure, context: :web).render?).to be false
        expect(described_class.new(source: :manual_after_api_failure).render?).to be false
      end

      it 'returns true for :manual only in buyer context' do
        expect(described_class.new(source: :manual, context: :buyer).render?).to be true
        expect(described_class.new(source: :manual, context: :web).render?).to be false
        expect(described_class.new(source: :manual).render?).to be false
      end

      it 'returns false when source is nil' do
        expect(described_class.new(source: nil).render?).to be false
      end

      it 'returns false without any parameters' do
        expect(described_class.new.render?).to be false
      end
    end
  end

  describe '#badge_text' do
    context 'when auto source' do
      it 'returns récupéré automatiquement' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :auto, value: { 'text' => 'Auto' })
        component = described_class.new(market_attribute_response: response)

        expect(component.badge_text).to eq('Récupéré automatiquement')
      end
    end

    context 'when manual_after_api_failure source in buyer context' do
      it 'returns déclaré par le candidat' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual_after_api_failure, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response, context: :buyer)

        expect(component.badge_text).to eq('Déclaré par le candidat')
      end
    end

    context 'when manual source in buyer context' do
      it 'returns déclaré par le candidat' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response, context: :buyer)

        expect(component.badge_text).to eq('Déclaré par le candidat')
      end
    end

    context 'with explicit source parameter' do
      it 'returns récupéré automatiquement when source is :auto' do
        expect(described_class.new(source: :auto).badge_text).to eq('Récupéré automatiquement')
      end

      it 'returns déclaré par le candidat when source is :manual_after_api_failure in buyer context' do
        expect(described_class.new(source: :manual_after_api_failure, context: :buyer).badge_text).to eq('Déclaré par le candidat')
      end

      it 'returns déclaré par le candidat when source is :manual in buyer context' do
        expect(described_class.new(source: :manual, context: :buyer).badge_text).to eq('Déclaré par le candidat')
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

    context 'when manual_after_api_failure source in buyer context' do
      it 'returns info badge classes' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual_after_api_failure, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response, context: :buyer)

        expect(component.badge_css_class).to eq('fr-badge fr-badge--info fr-badge--sm')
      end
    end

    context 'when manual source in buyer context' do
      it 'returns info badge classes' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual, value: { 'text' => 'Test' })
        component = described_class.new(market_attribute_response: response, context: :buyer)

        expect(component.badge_css_class).to eq('fr-badge fr-badge--info fr-badge--sm')
      end
    end
  end

  describe 'rendered output' do
    context 'when auto source' do
      it 'renders green badge in all contexts' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :auto, value: { 'text' => 'Auto' })

        render_inline(described_class.new(market_attribute_response: response, context: :buyer))
        expect(page).to have_css('span.fr-badge.fr-badge--success.fr-badge--sm')

        render_inline(described_class.new(market_attribute_response: response, context: :web))
        expect(page).to have_css('span.fr-badge.fr-badge--success.fr-badge--sm')
      end

      it 'does not include line break' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :auto, value: { 'text' => 'Auto' })
        render_inline(described_class.new(market_attribute_response: response))
        expect(rendered_content).not_to include('<br>')
      end
    end

    context 'when manual_after_api_failure source' do
      it 'renders blue badge only in buyer context' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual_after_api_failure, value: { 'text' => 'Test' })

        render_inline(described_class.new(market_attribute_response: response, context: :buyer))
        expect(page).to have_css('span.fr-badge.fr-badge--info.fr-badge--sm')

        render_inline(described_class.new(market_attribute_response: response, context: :web))
        expect(rendered_content).to be_blank

        render_inline(described_class.new(market_attribute_response: response, context: :pdf))
        expect(rendered_content).to be_blank
      end
    end

    context 'when manual source' do
      it 'renders blue badge only in buyer context' do
        response = create(:market_attribute_response_text_input, market_attribute:, source: :manual, value: { 'text' => 'Test' })

        render_inline(described_class.new(market_attribute_response: response, context: :buyer))
        expect(page).to have_css('span.fr-badge.fr-badge--info.fr-badge--sm')

        render_inline(described_class.new(market_attribute_response: response, context: :web))
        expect(rendered_content).to be_blank
      end
    end

    context 'without parameters' do
      it 'does not render' do
        render_inline(described_class.new)
        expect(rendered_content).to be_blank
      end
    end
  end
end
