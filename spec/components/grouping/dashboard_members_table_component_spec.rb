# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grouping::DashboardMembersTableComponent, type: :component do
  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  let(:grouping) { create(:grouping) }
  let(:presenter) { Candidate::GroupingDashboardPresenter.new(grouping.mandataire_market_application, grouping:) }

  it 'lists every member with their company, role, status and declared lots' do
    create(:grouping_member, :co_traitant, grouping:, company_name: 'Menuiseries Loire')

    render_inline(described_class.new(presenter:, market_application: grouping.mandataire_market_application))

    expect(page).to have_css('table')
    expect(page).to have_text('Menuiseries Loire')
    expect(page).to have_css('span.fr-badge', text: 'CO-TRAITANT')
  end

  it 'gives each member row a stable id for targeted updates' do
    member = create(:grouping_member, :co_traitant, grouping:)

    render_inline(described_class.new(presenter:, market_application: grouping.mandataire_market_application))

    expect(page).to have_css("tr#grouping_member_row_#{member.id}")
  end
end
