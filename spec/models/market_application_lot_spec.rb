# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketApplicationLot, type: :model do
  let(:public_market) { create(:public_market, :completed) }
  let(:market_application) { create(:market_application, public_market:) }
  let(:lot) { create(:lot, public_market:) }

  describe 'validations' do
    it 'prevents adding the same lot twice to an application' do
      create(:market_application_lot, market_application:, lot:)
      duplicate = build(:market_application_lot, market_application:, lot:)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:lot_id]).to be_present
    end

    it 'allows the same lot on different applications' do
      other_application = create(:market_application, public_market:)
      create(:market_application_lot, market_application:, lot:)
      other = build(:market_application_lot, market_application: other_application, lot:)

      expect(other).to be_valid
    end
  end
end
