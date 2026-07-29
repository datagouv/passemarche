# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grouping, type: :model do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe 'mandataire uniqueness per market' do
    it 'refuses a second grouping for a SIRET already mandataire on the same market' do
      mandataire_application = create(:market_application, public_market:, siret: '73282932000074',
        application_mode: :groupement)
      create(:grouping, public_market:, mandataire_market_application: mandataire_application)

      other_application = create(:market_application, public_market:, siret: '73282932000074',
        application_mode: :groupement)
      duplicate = build(:grouping, public_market:, mandataire_market_application: other_application)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:mandataire_siret]).to be_present
    end

    it 'is enforced at the database level even if the Ruby validation is bypassed (race condition safety net)' do
      mandataire_application = create(:market_application, public_market:, siret: '73282932000074',
        application_mode: :groupement)
      create(:grouping, public_market:, mandataire_market_application: mandataire_application)

      other_application = create(:market_application, public_market:, siret: '73282932000074',
        application_mode: :groupement)
      duplicate = build(:grouping, public_market:, mandataire_market_application: other_application,
        mandataire_siret: other_application.siret)

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows the same SIRET to be mandataire on different markets' do
      other_market = create(:public_market, :completed, editor:)
      first_application = create(:market_application, public_market:, siret: '73282932000074',
        application_mode: :groupement)
      create(:grouping, public_market:, mandataire_market_application: first_application)

      second_application = create(:market_application, public_market: other_market, siret: '73282932000074',
        application_mode: :groupement)
      grouping = build(:grouping, public_market: other_market, mandataire_market_application: second_application)

      expect(grouping).to be_valid
    end
  end

  describe '#legal_type' do
    it 'accepts conjoint, solidaire and conjoint_mandataire_solidaire' do
      application = create(:market_application, public_market:, application_mode: :groupement)
      grouping = build(:grouping, public_market:, mandataire_market_application: application,
        legal_type: :conjoint)
      expect(grouping).to be_legal_type_conjoint

      grouping.legal_type = :solidaire
      expect(grouping).to be_legal_type_solidaire

      grouping.legal_type = :conjoint_mandataire_solidaire
      expect(grouping).to be_legal_type_conjoint_mandataire_solidaire
    end
  end
end
