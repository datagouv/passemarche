# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grouping::BorderedBlockComponent, type: :component do
  it 'renders the title next to the given icon' do
    render_inline(described_class.new(icon_class: 'fr-icon-team-fill', title: 'Composition du groupement'))

    expect(page).to have_css('h2.fr-h6 span.fr-icon-team-fill')
    expect(page).to have_text('Composition du groupement')
  end

  it 'renders the block content passed to the yielded block' do
    render_inline(described_class.new(icon_class: 'fr-icon-team-fill', title: 'Composition du groupement')) do
      '<p class="member-content">Contenu</p>'.html_safe
    end

    expect(page).to have_css('p.member-content', text: 'Contenu')
  end

  it 'wraps everything in a bordered section' do
    render_inline(described_class.new(icon_class: 'fr-icon-team-fill', title: 'Titre'))

    expect(page).to have_css('section.fr-border.fr-border-default--grey')
  end
end
