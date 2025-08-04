# frozen_string_literal: true

FactoryBot.define do
  factory :public_market do
    editor
    identifier { nil }
    completed_at { nil }
    name { "Système d'acquisition dynamique pour matériels informatiques" }
    lot_name { 'Consommables informatiques neufs' }
    deadline { 1.month.from_now }
    market_type { 'supplies' }
    selected_optional_fields { [] }

    after(:build) do |public_market|
      if public_market.market_type_codes.empty?
        supplies_type = MarketType.find_or_create_by(code: 'supplies', deleted_at: nil)
        public_market.market_type_codes << supplies_type.code
      end
    end

    trait :completed do
      completed_at { Time.zone.now }
    end

    trait :without_lot do
      lot_name { nil }
    end
  end
end
