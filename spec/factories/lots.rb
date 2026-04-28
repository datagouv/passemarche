# frozen_string_literal: true

FactoryBot.define do
  factory :lot do
    association :public_market, :completed
    sequence(:name) { |n| "Lot #{n}" }
    position { nil }
  end
end
