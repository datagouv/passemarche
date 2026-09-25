# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Buyer::LotTypePickerPanelComponent, type: :component do
  it 'renders one radio option per active market type, disabled by default' do
    render_inline(described_class.new(picker_market_types:))

    expect(page).to have_field('market_type_works', type: 'radio', disabled: true)
    expect(page).to have_field('market_type_services', type: 'radio', disabled: true)
    expect(page).to have_field('market_type_supplies', type: 'radio', disabled: true)
  end

  it 'renders only the market types present in picker_market_types' do
    render_inline(described_class.new(picker_market_types: picker_market_types.slice('works')))

    expect(page).to have_field('market_type_works', type: 'radio', disabled: true)
    expect(page).not_to have_field('market_type_services', type: 'radio', disabled: :all)
  end

  it 'renders the cancel and apply actions, apply disabled by default' do
    render_inline(described_class.new(picker_market_types:))

    expect(page).to have_button('Annuler')
    expect(page).to have_button('Appliquer le nouveau type', disabled: true)
  end

  def picker_market_types
    @picker_market_types ||= {
      'works' => create(:market_type, :works),
      'services' => create(:market_type, :services),
      'supplies' => create(:market_type)
    }
  end
end
