# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::ApplicationModePresenter, type: :presenter do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:siret) { '73282932000074' }

  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  describe '#already_mandataire?' do
    it 'returns true when another application for the same SIRET and market is mandataire of a grouping' do
      mandataire_application = create(:market_application, public_market:, siret:, application_mode: :groupement)
      create(:grouping, public_market:, mandataire_market_application: mandataire_application)
      application = create(:market_application, public_market:, siret:, application_mode: :solo)

      presenter = described_class.new(application)

      expect(presenter.already_mandataire?).to be true
    end

    it 'returns false when no other application is mandataire' do
      application = create(:market_application, public_market:, siret:, application_mode: :solo)

      presenter = described_class.new(application)

      expect(presenter.already_mandataire?).to be false
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
end
