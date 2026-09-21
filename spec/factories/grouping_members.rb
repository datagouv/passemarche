# frozen_string_literal: true

FactoryBot.define do
  factory :grouping_member do
    grouping
    role { :co_traitant }
    sequence(:siret) { |n| "8888888888#{n.to_s.rjust(4, '0')}" }
    sequence(:email) { |n| "member#{n}@example.com" }

    trait :mandataire do
      role { :mandataire }
      market_application { grouping.mandataire_market_application }
    end

    trait :co_traitant do
      role { :co_traitant }
    end
  end
end
