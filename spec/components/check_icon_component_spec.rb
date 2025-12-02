# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CheckIconComponent, type: :component do
  describe 'web context' do
    it 'renders DSFR icon' do
      render_inline(CheckIconComponent.new(context: :web))
      expect(page).to have_css('.fr-icon-checkbox-circle-fill.fr-icon--sm[style*="color: #18753C"]')
    end
  end

  describe 'pdf context' do
    it 'renders SVG icon' do
      render_inline(CheckIconComponent.new(context: :pdf))
      expect(page).to have_css('svg[fill]', visible: :all).or have_css('svg > path[fill]', visible: :all)
    end
  end
end
