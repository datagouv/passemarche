# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grouping::MemberActionsComponent, type: :component do
  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  let(:grouping) { create(:grouping) }
  let(:presenter) { Candidate::GroupingDashboardPresenter.new(grouping.mandataire_market_application, grouping:) }

  it 'renders a copy link button once the invitation has been sent to a co_traitant' do
    member = create(:grouping_member, :co_traitant, grouping:, status: :invited,
      invitation_token: SecureRandom.hex, invitation_token_created_at: Time.current)

    render_inline(described_class.new(member:, market_application: grouping.mandataire_market_application, presenter:))

    expect(page).to have_button('Copier le lien')
  end

  it 'renders no action for a co_traitant when the invitation has not been sent yet' do
    member = create(:grouping_member, :co_traitant, grouping:, status: :invited)

    render_inline(described_class.new(member:, market_application: grouping.mandataire_market_application, presenter:))

    expect(page).not_to have_button('Copier le lien')
  end

  it 'renders an edit link for the mandataire when the application is in progress' do
    member = grouping.grouping_members.mandataire.first
    member.update!(status: :in_progress)

    render_inline(described_class.new(member:, market_application: grouping.mandataire_market_application, presenter:))

    expect(page).to have_css('a.fr-icon-edit-line')
  end

  it 'renders a consult link for the mandataire once completed' do
    member = grouping.grouping_members.mandataire.first
    member.update!(status: :completed)

    render_inline(described_class.new(member:, market_application: grouping.mandataire_market_application, presenter:))

    expect(page).to have_link('Consulter le formulaire')
  end

  it 'wraps the actions in a per-member container id' do
    member = create(:grouping_member, :co_traitant, grouping:)

    render_inline(described_class.new(member:, market_application: grouping.mandataire_market_application, presenter:))

    expect(page).to have_css("div#grouping_member_actions_#{member.id}")
  end
end
