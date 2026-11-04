# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::ApplicationModePresenter, type: :presenter do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:siret) { '73282932000074' }

  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  describe '#already_mandataire?' do
    it 'delegates to MarketApplication#already_mandataire_elsewhere?' do
      application = create(:market_application, public_market:, siret:, application_mode: :solo)
      allow(application).to receive(:already_mandataire_elsewhere?).and_return(true)

      presenter = described_class.new(application)

      expect(presenter.already_mandataire?).to be true
      expect(application).to have_received(:already_mandataire_elsewhere?)
    end
  end

  describe '#readonly?' do
    it 'returns true when the application already has a mode' do
      application = create(:market_application, public_market:, siret:, application_mode: :solo)

      expect(described_class.new(application).readonly?).to be true
    end

    it 'returns false when no mode has been chosen yet' do
      application = build(:market_application, public_market:, siret:, application_mode: nil)

      expect(described_class.new(application).readonly?).to be false
    end
  end

  describe '#mixte?, #solo_selected? and #groupement_selected?' do
    it 'selects solo when the application is solo only' do
      application = create(:market_application, public_market:, siret:, application_mode: :solo)
      presenter = described_class.new(application)

      expect(presenter.mixte?).to be false
      expect(presenter.solo_selected?).to be true
      expect(presenter.groupement_selected?).to be false
    end

    it 'selects groupement when the application is groupement only' do
      application = create(:market_application, public_market:, siret:, application_mode: :groupement)
      presenter = described_class.new(application)

      expect(presenter.mixte?).to be false
      expect(presenter.solo_selected?).to be false
      expect(presenter.groupement_selected?).to be true
    end

    it 'detects mixte when both a solo and a groupement counterpart exist' do
      create(:market_application, public_market:, siret:, application_mode: :solo)
      groupement = create(:market_application, public_market:, siret:, application_mode: :groupement)
      presenter = described_class.new(groupement)

      expect(presenter.mixte?).to be true
      expect(presenter.solo_selected?).to be false
      expect(presenter.groupement_selected?).to be false
    end

    it 'selects nothing when no mode has been chosen yet' do
      application = build(:market_application, public_market:, siret:, application_mode: nil)
      presenter = described_class.new(application)

      expect(presenter.mixte?).to be false
      expect(presenter.solo_selected?).to be false
      expect(presenter.groupement_selected?).to be false
    end
  end
end
