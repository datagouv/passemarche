# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shared::MarketInfoSidebarComponent, type: :component do
  it 'renders the buyer, market name and deadline rows' do
    render_inline(described_class.new(
      buyer_label: 'Acheteur',
      market_name: 'Mairie de Nulle Part',
      typology_label: 'Typologie',
      market_types_label: nil,
      deadline_label: 'Date limite',
      deadline: '01/01/2027 12:00'
    ))

    expect(page).to have_text('Acheteur')
    expect(page).to have_text('Mairie de Nulle Part')
    expect(page).to have_text('Date limite')
    expect(page).to have_text('01/01/2027 12:00')
  end

  it 'renders the typology row only when market_types_label is present' do
    render_inline(described_class.new(
      buyer_label: 'Acheteur',
      market_name: 'Mairie de Nulle Part',
      typology_label: 'Typologie',
      market_types_label: nil,
      deadline_label: 'Date limite',
      deadline: '01/01/2027 12:00'
    ))

    expect(page).not_to have_text('Typologie')
  end

  it 'renders the typology row when market_types_label is present' do
    render_inline(described_class.new(
      buyer_label: 'Acheteur',
      market_name: 'Mairie de Nulle Part',
      typology_label: 'Typologie',
      market_types_label: 'Travaux',
      deadline_label: 'Date limite',
      deadline: '01/01/2027 12:00'
    ))

    expect(page).to have_text('Typologie')
    expect(page).to have_text('Travaux')
  end
end
