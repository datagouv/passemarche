# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Buyer::LotTypeBadgeComponent, type: :component do
  it 'renders nothing when the lot has no market type at all' do
    lot = create(:lot)

    render_inline(described_class.new(lot:))

    expect(page.native.content).to be_blank
  end

  it 'renders a single badge with the effective market type when not overridden' do
    lot = create(:lot, :with_platform_type)

    render_inline(described_class.new(lot:))

    expect(page).to have_css('span.fr-badge', count: 1)
    expect(page).to have_text('FOURNITURES')
  end

  it 'renders a struck-through platform badge and the overriding badge when the buyer overrode the type' do
    lot = create(:lot, platform_market_type: create(:market_type, :services), market_type: create(:market_type, :works))

    render_inline(described_class.new(lot:))

    expect(page).to have_css('span.fr-badge', count: 2)
    expect(page).to have_css('span.buyer-lot-type-badge--struck-through', text: /SERVICES/)
    expect(page).to have_text('TRAVAUX')
  end
end
