# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupingMemberRemovalMailer, type: :mailer do
  let(:public_market) { create(:public_market, :completed, name: 'Marché test informatique') }
  let(:mandataire_application) do
    create(:market_application, public_market:, siret: '73282932000074', application_mode: :groupement)
  end
  let(:grouping) { create(:grouping, public_market:, mandataire_market_application: mandataire_application) }
  let(:co_traitant) do
    create(:grouping_member, :co_traitant, grouping:, email: 'contact@menuiseries-loire.fr',
      invitation_token_created_at: Time.current)
  end
  let(:removal) do
    co_traitant.destroy!
    PaperTrail::Version.find_by(item_type: 'GroupingMember', item_id: co_traitant.id, event: 'destroy')
  end

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
    grouping.mandataire_grouping_member.update!(company_name: 'Atlantique Bâtiment SAS')
  end

  describe '#removed' do
    let(:mail) { described_class.removed(removal) }

    it 'sends to the removed co-traitant email' do
      expect(mail.to).to eq(['contact@menuiseries-loire.fr'])
    end

    it 'uses the removal subject' do
      expect(mail.subject).to eq('Vous avez été retiré du groupement')
    end

    it 'names the mandataire and the market' do
      body = mail.html_part.body.decoded

      expect(body).to include('Atlantique Bâtiment SAS')
      expect(body).to include('pour le marché : Marché test informatique.')
    end

    it 'invites the co-traitant to contact the mandataire' do
      expect(mail.text_part.body.decoded).to include('Vous pouvez contacter directement le mandataire')
    end

    it 'embeds the logo as an inline attachment referenced by the html body' do
      logo = mail.attachments['passe-marche-logo-email.png']

      expect(logo).to be_inline
      expect(mail.html_part.body.decoded).to include("cid:#{logo.cid}")
    end

    it 'has no call to action' do
      expect(mail.html_part.body.decoded).not_to include('<a href="http')
    end

    context 'when the grouping no longer exists' do
      before do
        removal
        grouping.destroy!
      end

      it 'does not send anything' do
        expect(mail.message).to be_a(ActionMailer::Base::NullMail)
      end
    end
  end
end
