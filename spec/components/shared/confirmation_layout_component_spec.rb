# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shared::ConfirmationLayoutComponent, type: :component do
  it 'renders the content in the text column' do
    render_inline(described_class.new) { '<h3 class="fr-h3">Transmise</h3>'.html_safe }

    expect(page).to have_css('.fr-col-lg-7 h3', text: 'Transmise')
  end

  it 'renders the illustration in its own column' do
    render_inline(described_class.new) do |component|
      component.with_illustration { '<img alt="Succès" src="/success.png">'.html_safe }
      'Contenu'
    end

    expect(page).to have_css('.fr-col-lg-4 img[alt="Succès"]')
  end

  it 'omits the illustration column when none is given' do
    render_inline(described_class.new) { 'Contenu' }

    expect(page).to have_no_css('.fr-col-lg-4')
  end
end
