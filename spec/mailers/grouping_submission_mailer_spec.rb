# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupingSubmissionMailer, type: :mailer do
  let(:public_market) { create(:public_market, :completed, name: 'Marché test informatique') }
  let(:mandataire_application) do
    create(:market_application, public_market:, siret: '73282932000074', application_mode: :groupement)
  end
  let(:grouping) { create(:grouping, public_market:, mandataire_market_application: mandataire_application) }
  let(:co_traitant) { create(:grouping_member, :co_traitant, grouping:, email: 'contact@menuiseries-loire.fr') }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
    grouping.mandataire_grouping_member.update!(company_name: 'Atlantique Bâtiment SAS')
  end

  describe '#submitted' do
    let(:mail) { described_class.submitted(co_traitant) }

    it 'sends to the co-traitant email' do
      expect(mail.to).to eq(['contact@menuiseries-loire.fr'])
    end

    it 'uses the submission subject' do
      expect(mail.subject).to eq('Candidature transmise à la plateforme de marché')
    end

    it 'names the mandataire and the market' do
      body = mail.html_part.body.decoded

      expect(body).to include('Atlantique Bâtiment SAS')
      expect(body).to include('Marché test informatique')
    end

    it 'shows the market name without surrounding quotes' do
      body = mail.html_part.body.decoded

      expect(body).to include('pour le marché : Marché test informatique.')
      expect(body).not_to include('&ldquo;')
    end

    it 'has no call to action' do
      expect(mail.html_part.body.decoded).not_to include('<a href="http')
    end

    it 'tells the co-traitant their form is now locked' do
      expect(mail.text_part.body.decoded).to include('Vous ne pouvez plus modifier votre formulaire de candidature')
    end
  end
end
