# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::Shared::ProgressBarComponent, type: :component do
  describe '#container_css_class' do
    context 'when hidden is true' do
      it 'includes hidden class' do
        component = described_class.new(hidden: true)

        expect(component.container_css_class).to include('hidden')
      end
    end

    context 'when hidden is false' do
      it 'does not include hidden class' do
        component = described_class.new(hidden: false)

        expect(component.container_css_class).not_to include('hidden')
      end
    end

    it 'always includes fr-mt-1w class' do
      component = described_class.new

      expect(component.container_css_class).to include('fr-mt-1w')
    end
  end

  describe '#progress_bar_style' do
    it 'returns width style with progress percentage' do
      component = described_class.new(progress: 50)

      expect(component.progress_bar_style).to eq('width: 50%')
    end

    it 'defaults to 0%' do
      component = described_class.new

      expect(component.progress_bar_style).to eq('width: 0%')
    end
  end

  describe 'rendering' do
    it 'renders the progress container' do
      component = described_class.new

      render_inline(component)

      expect(page).to have_css('[data-direct-upload-target="progress"]')
    end

    it 'renders the progress bar' do
      component = described_class.new

      render_inline(component)

      expect(page).to have_css('[data-direct-upload-target="progressBar"]')
    end

    it 'renders with hidden class by default' do
      component = described_class.new

      render_inline(component)

      expect(page).to have_css('.hidden')
    end

    it 'renders visible when hidden is false' do
      component = described_class.new(hidden: false)

      render_inline(component)

      expect(page).not_to have_css('.hidden')
    end

    it 'applies progress width style' do
      component = described_class.new(progress: 75)

      render_inline(component)

      expect(page).to have_css('.direct-upload-progress-bar[style="width: 75%"]')
    end
  end
end
