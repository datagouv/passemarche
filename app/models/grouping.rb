# frozen_string_literal: true

class Grouping < ApplicationRecord
  belongs_to :public_market
  belongs_to :mandataire_market_application, class_name: 'MarketApplication'

  enum :legal_type, { conjoint: 0, solidaire: 1, conjoint_mandataire_solidaire: 2 }, prefix: true

  before_validation :set_mandataire_siret
  validates :mandataire_siret, presence: true, uniqueness: { scope: :public_market_id }

  private

  def set_mandataire_siret
    self.mandataire_siret = mandataire_market_application&.siret
  end
end
