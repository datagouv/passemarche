# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeArchiveService do
  describe '#perform' do
    context 'with an active attribute' do
      let(:attribute) { create(:market_attribute) }

      subject do
        service = described_class.new(market_attribute: attribute)
        service.perform
        service
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'sets deleted_at on the attribute' do
        subject
        expect(attribute.reload.deleted_at).to be_present
      end

      it 'returns the archived attribute as result' do
        expect(subject.result).to eq(attribute)
        expect(subject.result).to be_archived
      end
    end

    context 'with an already archived attribute' do
      let(:attribute) { create(:market_attribute, deleted_at: 1.day.ago) }

      subject do
        service = described_class.new(market_attribute: attribute)
        service.perform
        service
      end

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'has an error on market_attribute' do
        expect(subject.errors).to have_key(:market_attribute)
      end
    end
  end
end
