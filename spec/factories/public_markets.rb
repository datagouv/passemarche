# frozen_string_literal: true

FactoryBot.define do
  factory :public_market do
    editor
    identifier { nil }
    completed_at { nil }
    market_name { "Système d'acquisition dynamique pour matériels informatiques" }
    lot_name { 'Consommables informatiques neufs' }
    deadline { 1.month.from_now }
    market_type { 'Fournitures' }

    trait :completed do
      completed_at { Time.zone.now }
    end

    trait :without_lot do
      lot_name { nil }
    end
  end
end
