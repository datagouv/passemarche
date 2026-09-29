# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grouping::CompositionMembersTableComponent, type: :component do
  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  let(:grouping) { create(:grouping) }
  let(:market_application) { grouping.mandataire_market_application }

  it 'lists every member with their company, siret, email, role and status' do
    create(:grouping_member, :co_traitant, grouping:, company_name: 'Menuiseries Loire', email: 'contact@menuiseries-loire.fr')

    render_inline(described_class.new(grouping:, market_application:, editable: true))

    expect(page).to have_text('Menuiseries Loire')
    expect(page).to have_text('contact@menuiseries-loire.fr')
    expect(page).to have_css('span.fr-badge', text: 'CO-TRAITANT')
  end

  it 'shows a placeholder row when there is no co_traitant yet' do
    render_inline(described_class.new(grouping:, market_application:, editable: true))

    expect(page).to have_text(I18n.t('candidate.grouping_compositions.no_co_traitant_line1'))
  end

  context 'when editable' do
    it 'renders a remove button and its confirmation modal for a removable co_traitant' do
      member = create(:grouping_member, :co_traitant, grouping:)

      render_inline(described_class.new(grouping:, market_application:, editable: true))

      expect(page).to have_button(class: 'fr-icon-delete-line')
      expect(page).to have_css("dialog#removal-modal-#{member.id}")
    end

    it 'renders no remove button for a co_traitant whose application is already completed' do
      create(:grouping_member, :co_traitant, grouping:, status: :completed)

      render_inline(described_class.new(grouping:, market_application:, editable: true))

      expect(page).not_to have_button(class: 'fr-icon-delete-line')
    end
  end

  context 'when not editable' do
    it 'renders no remove button even for a removable co_traitant' do
      create(:grouping_member, :co_traitant, grouping:)

      render_inline(described_class.new(grouping:, market_application:, editable: false))

      expect(page).not_to have_button(class: 'fr-icon-delete-line')
    end
  end
end
