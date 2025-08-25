# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FieldConfigurationImport::SoftDeleteMissingFields, type: :interactor do
  subject(:interactor) { described_class.call(context) }

  let(:context) do
    Interactor::Context.build(
      imported_keys:,
      statistics: { soft_deleted: 0 }
    )
  end

  before do
    MarketAttribute.delete_all
  end

  describe '.call' do
    context 'when attributes exist that are not in imported keys' do
      let!(:kept_attribute) { create(:market_attribute, key: 'keep_me', deleted_at: nil) }
      let!(:deleted_attribute) { create(:market_attribute, key: 'delete_me', deleted_at: nil) }
      let!(:already_deleted) { create(:market_attribute, key: 'already_gone', deleted_at: 1.day.ago) }
      let(:imported_keys) { ['keep_me'] }

      it 'soft deletes missing attributes and tracks statistics' do
        freeze_time do
          interactor

          expect(kept_attribute.reload.deleted_at).to be_nil
          expect(deleted_attribute.reload.deleted_at).to eq(Time.current)
          expect(already_deleted.reload.deleted_at).to be_within(1.second).of(1.day.ago)
          expect(context.statistics[:soft_deleted]).to eq(1)
        end
      end
    end

    context 'when all active attributes are in imported keys' do
      let!(:attribute1) { create(:market_attribute, key: 'field1', deleted_at: nil) }
      let!(:attribute2) { create(:market_attribute, key: 'field2', deleted_at: nil) }
      let(:imported_keys) { %w[field1 field2] }

      it 'does not soft delete any attributes' do
        interactor

        expect(attribute1.reload.deleted_at).to be_nil
        expect(attribute2.reload.deleted_at).to be_nil
        expect(context.statistics[:soft_deleted]).to eq(0)
      end
    end
  end
end
