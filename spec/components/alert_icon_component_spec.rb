# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AlertIconComponent, type: :component do
  describe 'web context' do
    it 'renders DSFR alert icon' do
      render_inline(AlertIconComponent.new(context: :web))
      expect(page).to have_css('svg.fr-alert__icon[fill]', visible: :all)
    end
  end

  describe 'pdf context' do
    it 'renders unicode alert icon' do
      render_inline(AlertIconComponent.new(context: :pdf))
      expect(page).to have_css('span[aria-hidden="true"]', visible: :all)
      expect(page).to have_text('✖')
    end
  end
end
