# frozen_string_literal: true

FactoryBot.define do
  factory :grouping do
    association :public_market, :completed
    association :mandataire_market_application, factory: :market_application
    legal_type { :conjoint_mandataire_solidaire }
  end
end
