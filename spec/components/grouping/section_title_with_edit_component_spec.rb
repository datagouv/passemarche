# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grouping::SectionTitleWithEditComponent, type: :component do
  it 'renders the title and an edit link to the given path' do
    render_inline(described_class.new(title: 'Membres du groupement', edit_path: '/edit-members', edit_title: 'Modifier'))

    expect(page).to have_css('h3.fr-h6', text: 'Membres du groupement')
    expect(page).to have_css('a.fr-icon-edit-line[href="/edit-members"][title="Modifier"]')
  end
end
