# frozen_string_literal: true

class GroupingMember < ApplicationRecord
  belongs_to :grouping
  belongs_to :market_application, optional: true

  enum :role, { mandataire: 0, co_traitant: 1 }
  enum :status, { invited: 0, to_prepare: 1, in_progress: 2, completed: 3 }, prefix: true

  validates :siret, presence: true, siret: true
  validates :email, presence: true, if: :co_traitant?
  validates :grouping_id, uniqueness: { scope: :role }, if: :mandataire?
end
