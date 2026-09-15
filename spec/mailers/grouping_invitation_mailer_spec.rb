# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupingInvitationMailer, type: :mailer do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:, name: 'Marché test informatique') }
  let(:mandataire_application) do
    create(:market_application, public_market:, siret: '73282932000074', application_mode: :groupement)
  end
  let(:grouping) do
    create(:grouping, public_market:, mandataire_market_application: mandataire_application, legal_type: :conjoint)
  end
  let(:grouping_member) do
    create(:grouping_member, :co_traitant, grouping:, email: 'contact@menuiseries-loire.fr')
  end
  let(:url) { 'http://localhost:3000/candidate/grouping_invitations/abc123' }

  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  describe '#invitation' do
    let(:mail) { described_class.invitation(grouping_member, url) }

    it 'sends to the grouping member email' do
      expect(mail.to).to eq([grouping_member.email])
    end

    it 'sends from the application address' do
      expect(mail.from).to eq(['noreply@passemarche.data.gouv.fr'])
    end

    it 'includes the invitation URL in the text body' do
      expect(mail.text_part.body.decoded).to include(url)
    end

    it 'includes the market name in the html body' do
      expect(mail.html_part.body.decoded).to include('Marché test informatique')
    end
  end
end
