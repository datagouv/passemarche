# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MagicLinkEmailComponent, type: :component do
  describe 'outside a mailer' do
    it 'renders the logo from the asset pipeline' do
      render_inline(described_class.new(url: 'http://localhost:3000/auth/verify', market_name: 'Marché test'))

      expect(page).to have_css('img[src*="passe-marche-logo-email"]', visible: :all)
    end
  end
end
