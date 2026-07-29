# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupingMember, type: :model do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:mandataire_application) { create(:market_application, public_market:, application_mode: :groupement) }
  let(:grouping) { create(:grouping, public_market:, mandataire_market_application: mandataire_application) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe 'default status' do
    it 'starts as invited' do
      member = create(:grouping_member, grouping:)
      expect(member).to be_status_invited
    end
  end

  describe 'mandataire uniqueness within a grouping' do
    it 'refuses a second mandataire on the same grouping' do
      create(:grouping_member, :mandataire, grouping:)
      duplicate = build(:grouping_member, :mandataire, grouping:)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:grouping_id]).to be_present
    end

    it 'allows several co_traitant members on the same grouping' do
      create(:grouping_member, :co_traitant, grouping:)
      second = build(:grouping_member, :co_traitant, grouping:)

      expect(second).to be_valid
    end

    it 'is enforced at the database level even if the Ruby validation is bypassed (race condition safety net)' do
      create(:grouping_member, :mandataire, grouping:)
      duplicate = build(:grouping_member, :mandataire, grouping:)

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'market_application' do
    it 'can be blank until the co-traitant has joined' do
      member = build(:grouping_member, grouping:, market_application: nil)
      expect(member).to be_valid
    end
  end

  describe '#status' do
    it 'moves from invited to to_prepare to in_progress to completed' do
      member = create(:grouping_member, grouping:)

      member.status_to_prepare!
      expect(member).to be_status_to_prepare

      member.status_in_progress!
      expect(member).to be_status_in_progress

      member.status_completed!
      expect(member).to be_status_completed
    end
  end
end
