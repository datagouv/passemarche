# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicMarket, type: :model do
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
  end

  describe 'identifier generation' do
    let(:editor) { create(:editor) }
    let(:public_market) { build(:public_market, editor: editor, identifier: nil) }

    it 'generates an identifier before validation on create' do
      expect(public_market.identifier).to be_nil
      public_market.valid?
      expect(public_market.identifier).to match(/^VR-\d{4}-[A-Z0-9]{12}$/)
    end
  end
end
