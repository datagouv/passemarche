# frozen_string_literal: true

FactoryBot.define do
  factory :grouping do
    association :public_market, :completed
    legal_type { :conjoint_mandataire_solidaire }
  end
end
