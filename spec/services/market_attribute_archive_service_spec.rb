# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeArchiveService do
  describe '.call' do
    context 'with an active attribute' do
      let(:attribute) { create(:market_attribute) }

      it 'returns truthy' do
        expect(described_class.call(market_attribute: attribute)).to be_truthy
      end

      it 'sets deleted_at on the attribute' do
        described_class.call(market_attribute: attribute)
        expect(attribute.reload.deleted_at).to be_present
      end
    end

    context 'with an already archived attribute' do
      let(:attribute) { create(:market_attribute, deleted_at: 1.day.ago) }

      it 'returns false' do
        expect(described_class.call(market_attribute: attribute)).to be false
      end

      it 'does not change deleted_at' do
        expect { described_class.call(market_attribute: attribute) }
          .not_to change { attribute.reload.deleted_at }
      end
    end
  end
end
