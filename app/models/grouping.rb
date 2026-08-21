# frozen_string_literal: true

class Grouping < ApplicationRecord
  belongs_to :public_market

  has_many :grouping_members, dependent: :destroy
  has_many :market_applications, through: :grouping_members
  has_one :mandataire_grouping_member, -> { mandataire }, class_name: 'GroupingMember', inverse_of: :grouping
  has_one :mandataire_market_application, through: :mandataire_grouping_member, source: :market_application

  enum :legal_type, { conjoint: 0, solidaire: 1, conjoint_mandataire_solidaire: 2 }, prefix: true

  def all_members_completed?
    grouping_members.all?(&:status_completed?)
  end

  def any_member_started?
    grouping_members.any? { |member| member.status_in_progress? || member.status_completed? }
  end
end
