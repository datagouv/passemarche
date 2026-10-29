# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::DashboardMarketPresenter do
  let(:user) { create(:user) }
  let(:siret) { '73282932000074' }
  let(:public_market) { create(:public_market, :completed) }
  let(:market_applications) { MarketApplication.for_user(user).for_siret(siret) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe '.collection' do
    let(:other_market) { create(:public_market, :completed) }

    before do
      create(:market_application, public_market:, user:, siret:)
      create(:market_application, public_market: other_market, user:, siret:)
      create(:market_application, public_market:, siret:)
    end

    it 'builds one presenter per public market, in the given order' do
      markets = described_class.collection([other_market, public_market], market_applications)

      expect(markets.map(&:public_market)).to eq([other_market, public_market])
    end

    it 'only keeps the applications of the given scope' do
      markets = described_class.collection([public_market], market_applications)

      expect(markets.first.applications.size).to eq(1)
    end
  end

  describe '#applications' do
    subject(:presenter) { described_class.new(public_market, market_applications.to_a) }

    let!(:solo_application) { create(:market_application, public_market:, user:, siret:, application_mode: :solo) }
    let!(:mandataire_application) do
      create(:market_application, public_market:, user:, siret:, application_mode: :groupement).tap do |application|
        create(:grouping, public_market:, mandataire_market_application: application)
      end
    end
    let!(:co_traitant_application) do
      create(:market_application, public_market:, user:, siret:, application_mode: :groupement).tap do |application|
        other_mandataire = create(:market_application, public_market:, siret: '41816609600069', application_mode: :groupement)
        grouping = create(:grouping, public_market:, mandataire_market_application: other_mandataire)
        create(:grouping_member, :co_traitant, grouping:, market_application: application, siret:)
      end
    end

    it 'lists the mandataire, then the co-traitant, then the individual application' do
      expect(presenter.applications.map(&:market_application))
        .to eq([mandataire_application, co_traitant_application, solo_application])
    end
  end
end
