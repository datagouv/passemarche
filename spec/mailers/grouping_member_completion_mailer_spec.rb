# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupingMemberCompletionMailer, type: :mailer do
  let(:public_market) { create(:public_market, :completed, name: 'Marché test informatique') }
  let(:mandataire_application) do
    create(:market_application, public_market:, siret: '73282932000074', application_mode: :groupement)
  end
  let(:grouping) { create(:grouping, public_market:, mandataire_market_application: mandataire_application) }
  let(:co_traitant) do
    create(:grouping_member, :co_traitant, grouping:, company_name: 'Menuiseries de Loire SARL')
  end
  let(:dashboard_url) { 'https://example.com/candidate/market_applications/VR-1/grouping_dashboard' }

  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  describe '#completed' do
    let(:mail) { described_class.completed(co_traitant, 'mandataire@atlantique-batiment.fr', dashboard_url) }

    it 'sends to the mandataire email' do
      expect(mail.to).to eq(['mandataire@atlantique-batiment.fr'])
    end

    it 'uses the completion subject' do
      expect(mail.subject).to eq('Un co-traitant a complété son formulaire')
    end

    it 'names the co-traitant and the market' do
      body = mail.html_part.body.decoded

      expect(body).to include('<strong>Menuiseries de Loire SARL</strong>')
      expect(body).to include('pour le marché : Marché test informatique.')
    end

    it 'links to the mandataire dashboard' do
      expect(mail.html_part.body.decoded).to include(dashboard_url)
      expect(mail.html_part.body.decoded).to include('Voir mon tableau de bord')
    end

    context 'when the co-traitant company name is not resolved yet' do
      before { co_traitant.update!(company_name: nil) }

      it 'falls back to the SIRET' do
        expect(mail.text_part.body.decoded).to include(co_traitant.siret)
      end
    end
  end

  describe '#modified' do
    let(:mail) { described_class.modified(co_traitant, 'mandataire@atlantique-batiment.fr', dashboard_url) }

    it 'sends to the mandataire email' do
      expect(mail.to).to eq(['mandataire@atlantique-batiment.fr'])
    end

    it 'uses the modification subject' do
      expect(mail.subject).to eq('Un co-traitant a fait des modifications')
    end

    it 'names the co-traitant and the market' do
      body = mail.html_part.body.decoded

      expect(body).to include('<strong>Menuiseries de Loire SARL</strong> a modifié son formulaire')
      expect(body).to include('pour le marché : Marché test informatique.')
    end

    it 'links to the mandataire dashboard' do
      expect(mail.html_part.body.decoded).to include(dashboard_url)
      expect(mail.text_part.body.decoded).to include("Voir mon tableau de bord : #{dashboard_url}")
    end
  end
end
