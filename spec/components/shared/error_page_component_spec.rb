# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shared::ErrorPageComponent, type: :component do
  it 'renders the heading and every paragraph' do
    render_inline(described_class.new(heading: 'Page introuvable', paragraphs: ['Premier.', 'Second.']))

    expect(page).to have_css('h1.fr-h3', text: 'Page introuvable')
    expect(page).to have_css('p', text: 'Premier.')
    expect(page).to have_css('p', text: 'Second.')
  end

  it 'renders a decorative illustration' do
    render_inline(described_class.new(heading: 'Page introuvable', paragraphs: 'Texte.'))

    expect(page).to have_css('img[alt=""]')
  end

  it 'renders the action when given' do
    render_inline(described_class.new(heading: 'Page introuvable', paragraphs: 'Texte.')) do |component|
      component.with_action { '<a class="fr-btn" href="/">Retour</a>'.html_safe }
    end

    expect(page).to have_css('.fr-btns-group a.fr-btn', text: 'Retour')
  end

  it 'omits the action block when none is given' do
    render_inline(described_class.new(heading: 'Page introuvable', paragraphs: 'Texte.'))

    expect(page).to have_no_css('.fr-btns-group')
  end
end
