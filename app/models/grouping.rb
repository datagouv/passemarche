# frozen_string_literal: true

class Grouping < ApplicationRecord
  include Syncable

  class AlreadySubmittedError < StandardError; end

  belongs_to :public_market

  has_one_attached :attestation

  has_many :grouping_members, dependent: :destroy
  has_many :market_applications, through: :grouping_members
  has_one :mandataire_grouping_member, -> { mandataire }, class_name: 'GroupingMember', inverse_of: :grouping
  has_one :mandataire_market_application, through: :mandataire_grouping_member, source: :market_application

  enum :legal_type, { conjoint: 0, solidaire: 1, conjoint_mandataire_solidaire: 2 }, prefix: true
  enum :submission_mode, { full: 0, partial: 1 }, prefix: true, validate: { allow_nil: true }

  def all_members_completed?
    grouping_members.where.not(status: :completed).none?
  end

  def any_member_started?
    grouping_members.exists?(status: %i[in_progress completed])
  end

  def composition_confirmed?
    grouping_members.co_traitant.any?(&:invitation_sent?)
  end

  def submitted?
    submitted_at.present?
  end

  def submittable?
    !submitted? && all_members_completed?
  end

  def partially_submittable?
    !submitted? && any_member_started? && !all_members_completed?
  end

  def submit!(mode:)
    raise AlreadySubmittedError if submitted?

    update!(submitted_at: Time.zone.now, submission_mode: mode)
  end
end
