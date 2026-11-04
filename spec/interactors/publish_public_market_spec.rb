# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublishPublicMarket, type: :interactor do
  include ActiveSupport::Testing::TimeHelpers

  let(:editor) { create(:editor) }

  describe '.call' do
    context 'with a completed, non-published market' do
      let(:public_market) { create(:public_market, :completed, editor:) }

      it 'succeeds' do
        result = described_class.call(public_market:)
        expect(result).to be_success
      end

      it 'sets published_at' do
        freeze_time do
          described_class.call(public_market:)
          expect(public_market.reload.published_at).to eq(Time.zone.now)
        end
      end
    end

    context 'with a non-completed market' do
      let(:public_market) { create(:public_market, editor:) }

      it 'fails' do
        result = described_class.call(public_market:)
        expect(result).to be_failure
      end

      it 'returns an error' do
        result = described_class.call(public_market:)
        expect(result.errors[:base]).to include(I18n.t('api.errors.market_not_completed'))
      end
    end

    context 'with an already published market' do
      let(:public_market) { create(:public_market, :published, editor:) }

      it 'fails' do
        result = described_class.call(public_market:)
        expect(result).to be_failure
      end

      it 'returns an error' do
        result = described_class.call(public_market:)
        expect(result.errors[:base]).to include(I18n.t('api.errors.market_already_published'))
      end
    end
  end
end
