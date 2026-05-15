# frozen_string_literal: true

FactoryBot.define do
  factory :lot do
    association :public_market, :completed
    sequence(:name) { |n| "Lot #{n}" }
    position { nil }
    association :platform_market_type, factory: :market_type
  end
end
