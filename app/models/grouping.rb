# frozen_string_literal: true

class Grouping < ApplicationRecord
  belongs_to :public_market

  enum :legal_type, { conjoint: 0, solidaire: 1, conjoint_mandataire_solidaire: 2 }, prefix: true
end
