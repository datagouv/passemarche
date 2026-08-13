# frozen_string_literal: true

class GroupingMember < ApplicationRecord
  belongs_to :grouping
  belongs_to :public_market
  belongs_to :market_application, optional: true

  enum :role, { mandataire: 0, co_traitant: 1 }
  enum :status, { invited: 0, to_prepare: 1, in_progress: 2, completed: 3 }, prefix: true

  scope :mandataire_for, ->(public_market:, siret:) { mandataire.where(public_market:, siret:) }

  before_validation :set_public_market

  validates :siret, presence: true, siret: true
  validates :siret, uniqueness: { scope: :public_market_id }, if: :mandataire?
  validates :email, presence: true, if: :co_traitant?
  validates :grouping_id, uniqueness: { scope: :role }, if: :mandataire?
  validates :market_application, presence: true, if: :mandataire?

  private

  def set_public_market
    self.public_market_id = grouping.public_market_id if grouping
  end
end
