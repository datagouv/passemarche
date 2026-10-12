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

    it 'includes the mandataire company name in the html body' do
      grouping.mandataire_grouping_member.update!(company_name: 'Menuiseries de Loire SARL')

      expect(mail.html_part.body.decoded).to include('Menuiseries de Loire SARL')
    end

    it 'uses the invitation subject from the mockup' do
      expect(mail.subject).to eq('Vous êtes invité à rejoindre un groupement')
    end

    it 'shows the market name without surrounding quotes' do
      body = mail.html_part.body.decoded

      expect(body).to include('pour le marché : Marché test informatique.')
      expect(body).not_to include('&ldquo;')
    end

    it 'refers to the procurement platform rather than the buyer' do
      body = mail.text_part.body.decoded

      expect(body).to include('transmise à la plateforme de marché')
      expect(body).not_to include('acheteur')
    end

    it 'embeds the logo as an inline attachment referenced by the html body' do
      logo = mail.attachments['passe-marche-logo-email.png']

      expect(logo).to be_inline
      expect(mail.html_part.body.decoded).to include("cid:#{logo.cid}")
    end

    it 'does not attach the warning icon it does not display' do
      expect(mail.attachments['icon-email-warning.png']).to be_nil
    end

    it 'shows a single join call to action' do
      expect(mail.html_part.body.decoded).to include('Rejoindre le groupement').once
    end

    it 'falls back to the mandataire siret when no company name is set' do
      grouping.mandataire_grouping_member.update!(company_name: nil)

      expect(mail.html_part.body.decoded).to include(grouping.mandataire_grouping_member.siret)
    end
  end
end
