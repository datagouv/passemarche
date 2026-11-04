# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Buyer::LotRowComponent, type: :component do
  it 'renders the lot position, name and a checkbox scoped to that lot' do
    lot = create(:lot, name: 'Lot menuiserie', position: 2)

    render_inline(described_class.new(lot:))

    expect(page).to have_css("tr#lot_row_#{lot.id}")
    expect(page).to have_text('Lot menuiserie')
    expect(page).to have_field("lot_#{lot.id}", type: 'checkbox', visible: :all)
  end

  it 'renders the lot type badge component' do
    lot = create(:lot, :with_platform_type)

    render_inline(described_class.new(lot:))

    expect(page).to have_css('span.fr-badge')
  end
end
