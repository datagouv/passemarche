# frozen_string_literal: true

FactoryBot.define do
  factory :editor do
    sequence(:name) { |n| "Editor App #{n}" }
    sequence(:client_id) { |n| "client_id_#{n}_#{SecureRandom.hex(8)}" }
    client_secret { SecureRandom.hex(32) }
    authorized { false }
    active { true }

    trait :authorized do
      authorized { true }
    end

    trait :inactive do
      active { false }
    end

    trait :authorized_and_active do
      authorized { true }
      active { true }
    end

    factory :authorized_editor, traits: [:authorized]
    factory :inactive_editor, traits: [:inactive]
    factory :authorized_and_active_editor, traits: [:authorized_and_active]
  end
end
