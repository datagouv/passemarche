# frozen_string_literal: true

FactoryBot.define do
  factory :market_application_lot do
    association :market_application
    association :lot
  end
end
