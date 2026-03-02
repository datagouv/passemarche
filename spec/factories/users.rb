# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "candidat#{n}@example.com" }
  end
end
