# frozen_string_literal: true

class GroupingMember < ApplicationRecord
  belongs_to :grouping
  belongs_to :public_market
  belongs_to :market_application, optional: true, dependent: :destroy

  enum :role, { mandataire: 0, co_traitant: 1 }
  enum :status, { invited: 0, to_prepare: 1, in_progress: 2, completed: 3 }, prefix: true

  scope :mandataire_for, ->(public_market:, siret:) { mandataire.where(public_market:, siret:) }

  before_validation :set_public_market
  before_destroy :abort_if_completed
  after_create_commit :enqueue_company_name_resolution, if: :co_traitant?

  validates :siret, presence: true, siret: true
  validates :siret, uniqueness: { scope: :grouping_id }
  validates :siret, uniqueness: { scope: :public_market_id, conditions: -> { mandataire } }, if: :mandataire?
  validates :email, presence: true, email: true, if: :co_traitant?
  validates :grouping_id, uniqueness: { scope: :role }, if: :mandataire?
  validates :market_application, presence: true, if: :mandataire?
  validate :siret_not_mandataire, if: :co_traitant?

  def invitation_sent?
    invitation_token_created_at.present?
  end

  def declared_lots
    market_application&.lots || Lot.none
  end

  def mark_connected!
    status_to_prepare! if status_invited?
  end

  def mark_in_progress!
    status_in_progress! if status_to_prepare?
  end

  def mark_completed!
    status_completed! unless status_completed?
  end

  private

  def set_public_market
    self.public_market_id = grouping.public_market_id if grouping
  end

  def enqueue_company_name_resolution
    ResolveGroupingMemberCompanyNameJob.perform_later(id)
  end

  def siret_not_mandataire
    mandataire_siret = grouping&.mandataire_grouping_member&.siret
    return if siret != mandataire_siret

    errors.add(:siret, :same_as_mandataire)
  end

  def abort_if_completed
    return unless status_completed?

    errors.add(:base, I18n.t('candidate.validations.grouping_member_already_completed'))
    throw :abort
  end
end
