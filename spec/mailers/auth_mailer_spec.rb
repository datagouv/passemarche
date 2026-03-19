# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AuthMailer, type: :mailer do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:, name: 'Marché test informatique') }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }
  let(:user) { build(:user, email: 'candidat@example.com') }
  let(:url) { 'http://localhost:3000/auth/verify?token=abc123&market_application_id=VR-2024-ABC' }

  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  describe '#magic_link' do
    let(:mail) { described_class.magic_link(user, url, public_market.name) }

    it 'sends to the user email' do
      expect(mail.to).to eq([user.email])
    end

    it 'sends from the application address' do
      expect(mail.from).to eq(['noreply@passemarche.data.gouv.fr'])
    end

    it 'includes the magic link URL in the text body' do
      expect(mail.text_part.body.decoded).to include(url)
    end

    it 'includes the market name in the html body' do
      expect(mail.html_part.body.decoded).to include('Marché test informatique')
    end
  end
end
