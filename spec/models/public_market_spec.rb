# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicMarket, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  subject(:public_market) { build(:public_market) }

  describe 'validations' do
    let(:editor) { create(:editor) }

    describe 'identifier validation' do
      it 'validates presence of identifier' do
        public_market = build(:public_market, editor: editor, identifier: nil)
        public_market.valid?
        expect(public_market.identifier).to be_present
      end

      it 'validates uniqueness of identifier' do
        existing_market = create(:public_market, editor: editor)
        duplicate_market = build(:public_market, editor: editor, identifier: existing_market.identifier)
        expect(duplicate_market).not_to be_valid
        expect(duplicate_market.errors[:identifier]).to be_present
      end
    end

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:deadline) }

    describe 'market_type_codes validation' do
      let(:supplies_market_type) { create(:market_type, code: 'supplies') }
      let(:services_market_type) { create(:market_type, code: 'services') }

      before do
        supplies_market_type
        services_market_type
      end

      it 'accepts valid market type codes' do
        public_market = build(:public_market, editor: editor, market_type_codes: ['supplies'])
        expect(public_market).to be_valid
      end

      it 'rejects invalid market type codes' do
        public_market = build(:public_market, editor: editor, market_type_codes: ['invalid_code'])
        expect(public_market).not_to be_valid
        expect(public_market.errors[:market_type_codes]).to include('contient des codes invalides : invalid_code')
      end

      it 'rejects mix of valid and invalid codes' do
        public_market = build(:public_market, editor: editor, market_type_codes: %w[supplies invalid_code])
        expect(public_market).not_to be_valid
        expect(public_market.errors[:market_type_codes]).to include('contient des codes invalides : invalid_code')
      end
    end
  end

  describe 'callbacks' do
    describe 'generate_identifier' do
      let(:editor) { create(:editor) }
      let(:public_market) { build(:public_market, editor: editor, identifier: nil) }

      it 'generates an identifier before validation on create' do
        expect(public_market.identifier).to be_nil
        public_market.valid?
        expect(public_market.identifier).to match(/^VR-\d{4}-[A-Z0-9]{12}$/)
      end

      it 'does not override existing identifier' do
        existing_identifier = 'CUSTOM-ID'
        public_market = build(:public_market, editor: editor, identifier: existing_identifier)
        public_market.save!

        expect(public_market.identifier).to eq(existing_identifier)
      end
    end
  end

  describe '#complete!' do
    let(:editor) { create(:editor) }
    let(:public_market) { create(:public_market, editor: editor) }

    it 'sets completed_at to current time' do
      freeze_time do
        public_market.complete!
        expect(public_market.completed_at).to eq(Time.zone.now)
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
