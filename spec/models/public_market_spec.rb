# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicMarket, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  subject(:public_market) { build(:public_market) }

  describe 'associations' do
    let(:editor) { create(:editor) }

    it 'can have many lots' do
      market = create(:public_market, :completed, editor:)
      create(:lot, public_market: market)
      create(:lot, public_market: market)

      expect(market.lots.count).to eq(2)
    end

    it 'destroys lots when destroyed' do
      market = create(:public_market, :completed, editor:)
      create(:lot, public_market: market)

      expect { market.destroy }.to change(Lot, :count).by(-1)
    end
  end

  describe 'validations' do
    let(:editor) { create(:editor) }

    describe 'identifier validation' do
      it 'validates presence of identifier' do
        public_market = build(:public_market, editor:, identifier: nil)
        public_market.valid?
        expect(public_market.identifier).to be_present
      end

      it 'validates uniqueness of identifier' do
        existing_market = create(:public_market, editor:)
        duplicate_market = build(:public_market, editor:, identifier: existing_market.identifier)
        expect(duplicate_market).not_to be_valid
        expect(duplicate_market.errors[:identifier]).to be_present
      end
    end

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:deadline) }
    it { should validate_presence_of(:siret) }

    describe 'siret validation' do
      it 'accepts valid SIRET' do
        public_market = build(:public_market, editor:, siret: '13002526500013')
        expect(public_market).to be_valid
      end

      it 'rejects SIRET with invalid format (not 14 digits)' do
        public_market = build(:public_market, editor:, siret: '1300252650001')
        expect(public_market).not_to be_valid
        expect(public_market.errors[:siret]).to include('Le numéro de SIRET saisi est invalide ou non reconnu')
      end

      it 'rejects SIRET with invalid Luhn checksum' do
        public_market = build(:public_market, editor:, siret: '13002526500014')
        expect(public_market).not_to be_valid
        expect(public_market.errors[:siret]).to include('Le numéro de SIRET saisi est invalide ou non reconnu')
      end

      it 'accepts La Poste SIRET (special case)' do
        public_market = build(:public_market, editor:, siret: '35600000012345')
        expect(public_market).to be_valid
      end

      it 'rejects non-numeric SIRET' do
        public_market = build(:public_market, editor:, siret: 'ABCD1234567890')
        expect(public_market).not_to be_valid
        expect(public_market.errors[:siret]).to include('Le numéro de SIRET saisi est invalide ou non reconnu')
      end
    end

    describe 'lot_limit validation' do
      let(:editor) { create(:editor) }

      it 'accepts lot_limit equal to the number of lots' do
        public_market = build(:public_market, editor:, lot_limit: 2,
          lots_attributes: [{ name: 'Lot 1', position: 1 }, { name: 'Lot 2', position: 2 }])
        expect(public_market).to be_valid
      end

      it 'accepts lot_limit below the number of lots' do
        public_market = build(:public_market, editor:, lot_limit: 1,
          lots_attributes: [{ name: 'Lot 1', position: 1 }, { name: 'Lot 2', position: 2 }])
        expect(public_market).to be_valid
      end

      it 'rejects lot_limit exceeding the number of lots' do
        public_market = build(:public_market, editor:, lot_limit: 3,
          lots_attributes: [{ name: 'Lot 1', position: 1 }, { name: 'Lot 2', position: 2 }])
        expect(public_market).not_to be_valid
        expect(public_market.errors[:lot_limit]).to include(
          'Vous ne pouvez pas limiter un nombre de lots supérieur au nombre de lots créés.'
        )
      end

      it 'accepts nil lot_limit' do
        public_market = build(:public_market, editor:, lot_limit: nil)
        expect(public_market).to be_valid
      end
    end

    describe 'provider_user_id validation' do
      it 'accepts nil provider_user_id' do
        public_market = build(:public_market, editor:, provider_user_id: nil)
        expect(public_market).to be_valid
      end

      it 'accepts valid provider_user_id' do
        public_market = build(:public_market, editor:, provider_user_id: 'editor-user-123')
        expect(public_market).to be_valid
      end

      it 'rejects provider_user_id longer than 255 characters' do
        public_market = build(:public_market, editor:, provider_user_id: 'a' * 256)
        expect(public_market).not_to be_valid
        expect(public_market.errors[:provider_user_id]).to be_present
      end
    end

    describe 'market_type_codes validation' do
      let(:supplies_market_type) { create(:market_type, code: 'supplies') }
      let(:services_market_type) { create(:market_type, code: 'services') }

      before do
        supplies_market_type
        services_market_type
      end

      it 'accepts valid market type codes' do
        public_market = build(:public_market, editor:, market_type_codes: ['supplies'])
        expect(public_market).to be_valid
      end

      it 'rejects invalid market type codes' do
        public_market = build(:public_market, editor:, market_type_codes: ['invalid_code'])
        expect(public_market).not_to be_valid
        expect(public_market.errors[:market_type_codes]).to include('Les codes de marché contiennent des valeurs invalides : invalid_code')
      end

      it 'rejects mix of valid and invalid codes' do
        public_market = build(:public_market, editor:, market_type_codes: %w[supplies invalid_code])
        expect(public_market).not_to be_valid
        expect(public_market.errors[:market_type_codes]).to include('Les codes de marché contiennent des valeurs invalides : invalid_code')
      end
    end
  end

  describe 'callbacks' do
    describe 'generate_identifier' do
      let(:editor) { create(:editor) }
      let(:public_market) { build(:public_market, editor:, identifier: nil) }

      it 'generates an identifier before validation on create' do
        expect(public_market.identifier).to be_nil
        public_market.valid?
        expect(public_market.identifier).to match(/^VR-\d{4}-[A-Z0-9]{12}$/)
      end

      it 'does not override existing identifier' do
        existing_identifier = 'CUSTOM-ID'
        public_market = build(:public_market, editor:, identifier: existing_identifier)
        public_market.save!

        expect(public_market.identifier).to eq(existing_identifier)
      end
    end
  end

  describe '#update_and_resync_configuration!' do
    let(:editor) { create(:editor) }

    context 'when the market is already completed' do
      let(:public_market) { create(:public_market, :completed, editor:) }

      it 'updates the given attributes' do
        new_deadline = 2.months.from_now
        public_market.update_and_resync_configuration!(deadline: new_deadline)

        expect(public_market.reload.deadline).to be_within(1.second).of(new_deadline)
      end

      it 'enqueues the configuration summary PDF regeneration job' do
        expect do
          public_market.update_and_resync_configuration!(deadline: 2.months.from_now)
        end.to have_enqueued_job(GeneratePublicMarketConfigurationSummaryPdfJob).with(public_market.id)
      end

      it 'does not enqueue the configuration summary PDF regeneration job when the update is a no-op' do
        expect do
          public_market.update_and_resync_configuration!(deadline: public_market.deadline)
        end.not_to have_enqueued_job(GeneratePublicMarketConfigurationSummaryPdfJob)
      end
    end

    context 'when the market is not completed' do
      let(:public_market) { create(:public_market, editor:) }

      it 'updates the given attributes' do
        new_deadline = 2.months.from_now
        public_market.update_and_resync_configuration!(deadline: new_deadline)

        expect(public_market.reload.deadline).to be_within(1.second).of(new_deadline)
      end

      it 'does not enqueue the configuration summary PDF regeneration job' do
        expect do
          public_market.update_and_resync_configuration!(deadline: 2.months.from_now)
        end.not_to have_enqueued_job(GeneratePublicMarketConfigurationSummaryPdfJob)
      end
    end
  end

  describe '#complete!' do
    let(:editor) { create(:editor) }
    let(:public_market) { create(:public_market, editor:) }

    it 'sets completed_at to current time' do
      freeze_time do
        public_market.complete!
        expect(public_market.completed_at).to eq(Time.zone.now)
      end
    end
  end

  describe '#published?' do
    it 'returns true when published_at is present' do
      public_market = build(:public_market, published_at: Time.zone.now)
      expect(public_market).to be_published
    end

    it 'returns false when published_at is nil' do
      public_market = build(:public_market, published_at: nil)
      expect(public_market).not_to be_published
    end
  end

  describe '#publish!' do
    let(:editor) { create(:editor) }
    let(:public_market) { create(:public_market, editor:) }

    it 'sets published_at to current time' do
      freeze_time do
        public_market.publish!
        expect(public_market.published_at).to eq(Time.zone.now)
      end
    end
  end

  describe 'sync status helpers' do
    let(:public_market) { build(:public_market) }

    describe '#sync_in_progress?' do
      it 'returns true for pending status' do
        public_market.sync_status = 'sync_pending'
        expect(public_market).to be_sync_in_progress
      end

      it 'returns true for processing status' do
        public_market.sync_status = 'sync_processing'
        expect(public_market).to be_sync_in_progress
      end

      it 'returns false for completed status' do
        public_market.sync_status = 'sync_completed'
        expect(public_market).not_to be_sync_in_progress
      end

      it 'returns false for failed status' do
        public_market.sync_status = 'sync_failed'
        expect(public_market).not_to be_sync_in_progress
      end
    end
  end

  describe '#open?' do
    it 'returns true when deadline is in the future' do
      public_market = build(:public_market, deadline: 1.hour.from_now)
      expect(public_market).to be_open
    end

    it 'returns false when deadline is in the past' do
      public_market = build(:public_market, deadline: 1.hour.ago)
      expect(public_market).not_to be_open
    end

    it 'returns false when deadline is exactly now' do
      freeze_time do
        public_market = build(:public_market, deadline: Time.zone.now)
        expect(public_market).not_to be_open
      end
    end
  end

  describe '#buyer_display_name' do
    it 'returns the buyer_name when present' do
      public_market = build(:public_market, buyer_name: 'Ville de Paris')
      expect(public_market.buyer_display_name).to eq('Ville de Paris')
    end

    it 'falls back to siret when buyer_name is blank' do
      public_market = build(:public_market, buyer_name: nil)
      expect(public_market.buyer_display_name).to eq(public_market.siret)
    end
  end

  describe '#multi_type_lots?' do
    let(:works_type)    { create(:market_type, :works) }
    let(:services_type) { create(:market_type, :services) }
    let(:market)        { create(:public_market, :completed) }

    context 'sans lot' do
      it 'retourne false' do
        expect(market.multi_type_lots?).to be false
      end
    end

    context 'avec des lots tous du même type' do
      before do
        create(:lot, public_market: market, market_type: works_type)
        create(:lot, public_market: market, market_type: works_type)
      end

      it 'retourne false' do
        expect(market.multi_type_lots?).to be false
      end
    end

    context 'avec des lots de types différents' do
      before do
        create(:lot, public_market: market, market_type: works_type)
        create(:lot, public_market: market, market_type: services_type)
      end

      it 'retourne true' do
        expect(market.multi_type_lots?).to be true
      end
    end

    context 'avec des lots sans type (platform_market_type uniquement)' do
      before do
        create(:lot, public_market: market, platform_market_type: works_type)
        create(:lot, public_market: market, platform_market_type: services_type)
      end

      it 'retourne true en utilisant le type effectif' do
        expect(market.multi_type_lots?).to be true
      end
    end

    context 'avec des lots sans aucun type' do
      before { create(:lot, public_market: market) }

      it 'retourne false' do
        expect(market.multi_type_lots?).to be false
      end
    end
  end

  describe '#update_lot_types' do
    let!(:works_type) { create(:market_type, :works) }
    let!(:services_type) { create(:market_type, :services) }
    let(:market) { create(:public_market, :completed, market_type_codes: ['works']) }
    let!(:kept_works_lot) { create(:lot, public_market: market, market_type: works_type) }
    let(:lot) { create(:lot, public_market: market, market_type: services_type) }
    let(:works_attribute) { create(:market_attribute, market_types: [works_type]) }
    let(:services_attribute) { create(:market_attribute, market_types: [services_type]) }
    let(:common_attribute) { create(:market_attribute, market_types: [works_type, services_type]) }

    before do
      market.market_attributes << [works_attribute, services_attribute, common_attribute]
    end

    context 'quand un lot change vers un type qui retire le dernier lot de son type précédent' do
      it 'retire les exigences propres au type de lot disparu' do
        market.update_lot_types([lot.id], works_type)

        expect(market.reload.market_attributes).not_to include(services_attribute)
      end

      it 'conserve les exigences communes à plusieurs types' do
        market.update_lot_types([lot.id], works_type)

        expect(market.reload.market_attributes).to include(common_attribute)
      end

      it 'conserve les exigences du type toujours porté par un autre lot' do
        market.update_lot_types([lot.id], works_type)

        expect(market.reload.market_attributes).to include(works_attribute)
      end
    end

    context 'quand le type retiré reste présent via market_type_codes du marché' do
      let(:market) { create(:public_market, :completed, market_type_codes: %w[works services]) }

      it 'ne retire pas les exigences de ce type' do
        market.update_lot_types([lot.id], works_type)

        expect(market.reload.market_attributes).to include(services_attribute)
      end
    end

    context 'quand un type retiré est ré-ajouté ensuite' do
      let(:mandatory_services_attribute) { create(:market_attribute, market_types: [services_type], mandatory: true) }
      let(:optional_services_attribute) { create(:market_attribute, market_types: [services_type], mandatory: false) }

      before do
        market.market_attributes << [mandatory_services_attribute, optional_services_attribute]
      end

      it 'restaure les exigences obligatoires du type retrouvé' do
        market.update_lot_types([lot.id], works_type)
        market.update_lot_types([lot.id], services_type)

        expect(market.reload.market_attributes).to include(mandatory_services_attribute)
      end

      it 'ne restaure pas les exigences optionnelles précédemment sélectionnées' do
        market.update_lot_types([lot.id], works_type)
        market.update_lot_types([lot.id], services_type)

        expect(market.reload.market_attributes).not_to include(optional_services_attribute, services_attribute)
      end
    end

    context 'quand le type de lot ne change pas' do
      let(:market) { create(:public_market, :completed, market_type_codes: %w[works services]) }

      it 'ne retire aucune exigence' do
        market.update_lot_types([lot.id], services_type)

        expect(market.reload.market_attributes).to include(works_attribute, services_attribute, common_attribute)
      end
    end

    context 'quand le changement retirerait le dernier lot de la typologie du marché' do
      it 'refuse la modification' do
        result = market.update_lot_types([kept_works_lot.id], services_type)

        expect(result).to be false
      end

      it 'ne modifie pas le type du lot' do
        market.update_lot_types([kept_works_lot.id], services_type)

        expect(kept_works_lot.reload.effective_market_type).to eq(works_type)
      end

      it 'ajoute une erreur sur le marché' do
        market.update_lot_types([kept_works_lot.id], services_type)

        expect(market.errors[:base]).to be_present
      end
    end

    context 'quand un autre lot conserve la typologie du marché' do
      it 'autorise la modification' do
        result = market.update_lot_types([lot.id], works_type)

        expect(result).to be true
      end
    end

    context 'quand le marché a plusieurs typologies déclarées' do
      let(:market) { create(:public_market, :completed, market_type_codes: %w[works services]) }
      let!(:other_works_lot) { create(:lot, public_market: market, market_type: works_type) }
      let!(:kept_services_lot) { create(:lot, public_market: market, market_type: services_type) }

      it 'refuse de retirer le dernier lot de la deuxième typologie' do
        result = market.update_lot_types([kept_services_lot.id, lot.id], works_type)

        expect(result).to be false
      end

      it 'ne modifie pas le type du lot pour la deuxième typologie' do
        market.update_lot_types([kept_services_lot.id, lot.id], works_type)

        expect(kept_services_lot.reload.effective_market_type).to eq(services_type)
      end

      it 'autorise de retirer un lot qui ne vide aucune des deux typologies' do
        result = market.update_lot_types([other_works_lot.id], services_type)

        expect(result).to be true
      end
    end

    context 'quand aucun lot n\'est sélectionné' do
      it 'refuse la modification' do
        result = market.update_lot_types([], services_type)

        expect(result).to be false
      end

      it 'ajoute une erreur sur le marché' do
        market.update_lot_types([], services_type)

        expect(market.errors[:base]).to be_present
      end

      it 'ne modifie aucune exigence' do
        market.update_lot_types([], services_type)

        expect(market.reload.market_attributes).to include(works_attribute, services_attribute, common_attribute)
      end
    end

    context 'quand un premier appel échoue puis un second réussit' do
      it 'ne conserve pas les erreurs du premier appel' do
        market.update_lot_types([kept_works_lot.id], services_type)
        result = market.update_lot_types([lot.id], works_type)

        expect(result).to be true
        expect(market.errors[:base]).to be_empty
      end
    end
  end

  describe '#defense_industry?' do
    it 'returns true when defense is in market_type_codes' do
      public_market = build(:public_market, market_type_codes: %w[supplies defense])
      expect(public_market).to be_defense_industry
    end

    it 'returns false when defense is not in market_type_codes' do
      public_market = build(:public_market, market_type_codes: %w[supplies services])
      expect(public_market).not_to be_defense_industry
    end
  end
end
