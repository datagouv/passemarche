# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GroupingMember, type: :model do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:grouping) { create(:grouping, public_market:) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe 'default status' do
    it 'starts as invited' do
      member = create(:grouping_member, :co_traitant, grouping:)
      expect(member).to be_status_invited
    end
  end

  describe 'mandataire uniqueness within a grouping' do
    it 'refuses a second mandataire on the same grouping' do
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
      duplicate = build(:grouping_member, :mandataire, grouping:, public_market:)

      expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'market_application' do
    it 'can be blank until the co-traitant has joined' do
      member = build(:grouping_member, :co_traitant, grouping:, market_application: nil)
      expect(member).to be_valid
    end

    it 'is required for the mandataire, who always has an application from the start' do
      member = build(:grouping_member, :mandataire, grouping:, market_application: nil)

      expect(member).not_to be_valid
      expect(member.errors[:market_application]).to be_present
    end
  end

  describe 'email' do
    it 'is required for a co_traitant' do
      member = build(:grouping_member, :co_traitant, grouping:, email: nil)
      expect(member).not_to be_valid
      expect(member.errors[:email]).to be_present
    end

    it 'is not required for the mandataire' do
      member = grouping.mandataire_grouping_member
      member.email = nil

      expect(member).to be_valid
    end
  end

  describe '#status' do
    it 'moves from invited to to_prepare to in_progress to completed' do
      member = create(:grouping_member, :co_traitant, grouping:)

      member.status_to_prepare!
      expect(member).to be_status_to_prepare

      member.status_in_progress!
      expect(member).to be_status_in_progress

      member.status_completed!
      expect(member).to be_status_completed
    end
  end

  describe '#mark_connected!' do
    it 'moves an invited member to to_prepare' do
      member = create(:grouping_member, :co_traitant, grouping:)

      member.mark_connected!

      expect(member).to be_status_to_prepare
    end

    it 'does not move back a member already further along' do
      member = create(:grouping_member, :co_traitant, grouping:, status: :in_progress)

      member.mark_connected!

      expect(member).to be_status_in_progress
    end
  end

  describe '#mark_in_progress!' do
    it 'moves a to_prepare member to in_progress' do
      member = create(:grouping_member, :co_traitant, grouping:, status: :to_prepare)

      member.mark_in_progress!

      expect(member).to be_status_in_progress
    end

    it 'does not move back a completed member' do
      member = create(:grouping_member, :co_traitant, grouping:, status: :completed)

      member.mark_in_progress!

      expect(member).to be_status_completed
    end

    it 'does not move an invited member directly to in_progress' do
      member = create(:grouping_member, :co_traitant, grouping:)

      member.mark_in_progress!

      expect(member).to be_status_invited
    end
  end

  describe '#mark_completed!' do
    it 'moves any non-completed member to completed' do
      member = create(:grouping_member, :co_traitant, grouping:, status: :in_progress)

      member.mark_completed!

      expect(member).to be_status_completed
    end
  end

  describe '#declared_lots' do
    it 'delegates to the member market_application lots' do
      lot = create(:lot, public_market:)
      application = create(:market_application, public_market:, application_mode: :groupement)
      create(:market_application_lot, market_application: application, lot:)
      member = create(:grouping_member, :co_traitant, grouping:, market_application: application)

      expect(member.declared_lots).to contain_exactly(lot)
    end

    it 'is empty when the member has no market_application yet' do
      member = create(:grouping_member, :co_traitant, grouping:, market_application: nil)

      expect(member.declared_lots).to be_empty
    end
  end

  describe 'siret' do
    it 'rejects a co_traitant siret equal to the mandataire siret' do
      member = build(:grouping_member, :co_traitant, grouping:, siret: grouping.mandataire_grouping_member.siret)

      expect(member).not_to be_valid
      expect(member.errors[:siret]).to be_present
    end

    it 'allows the mandataire own member to have the mandataire siret' do
      expect(grouping.mandataire_grouping_member).to be_valid
    end

    it 'is enforced unique within a grouping at the database level' do
      create(:grouping_member, :co_traitant, grouping:, siret: '80245139600027')
      duplicate = build(:grouping_member, :co_traitant, grouping:, siret: '80245139600027')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:siret]).to be_present
    end
  end

  describe '#invitation_sent?' do
    it 'is false when the invitation has not been sent yet' do
      member = build(:grouping_member, :co_traitant, grouping:, invitation_token_created_at: nil)
      expect(member.invitation_sent?).to be false
    end

    it 'is true once the invitation has been sent' do
      member = build(:grouping_member, :co_traitant, grouping:, invitation_token_created_at: Time.current)
      expect(member.invitation_sent?).to be true
    end
  end
end
