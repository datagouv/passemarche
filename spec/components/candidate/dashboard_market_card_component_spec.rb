# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::DashboardMarketCardComponent, type: :component do
  let(:user) { create(:user) }
  let(:public_market) { create(:public_market, :completed, name: 'Rénovation du gymnase', buyer_name: 'Ville de Pessac') }

  before do
    create(:market_application, public_market:, user:, application_mode: :solo)
    create(:market_application, public_market:, user:, application_mode: :solo, siret: '41816609600069')
    allow(SiretValidator).to receive(:valid?).and_return(true)

    market = Candidate::DashboardMarketPresenter.collection([public_market], MarketApplication.for_user(user)).first
    render_inline(described_class.new(market:))
  end

  it 'renders the market name and its buyer' do
    expect(page).to have_css('h2', text: 'Rénovation du gymnase')
    expect(page).to have_text('Ville de Pessac')
  end

  it 'renders one row per application' do
    expect(page).to have_css('.dashboard-application-row', count: 2)
  end
end
