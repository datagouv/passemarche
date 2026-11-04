# frozen_string_literal: true

FactoryBot.define do
  factory :public_market do
    editor
    identifier { nil }
    completed_at { nil }
    name { "Système d'acquisition dynamique pour matériels informatiques" }
    deadline { 1.month.from_now }
    siret { '13002526500013' }

    after(:build) do |public_market|
      if public_market.market_type_codes.empty?
        supplies_type = MarketType.find_or_create_by(code: 'supplies', deleted_at: nil)
        public_market.market_type_codes << supplies_type.code
      end
    end

    trait :completed do
      completed_at { Time.zone.now }
      sync_status { :sync_completed }
    end

    trait :published do
      completed_at { Time.zone.now }
      published_at { Time.zone.now }
      sync_status { :sync_completed }
    end

    trait :with_provider_user_id do
      provider_user_id { 'editor-user-123' }
    end

    trait :multi_type do
      after(:create) do |market|
        works_type    = MarketType.find_or_create_by!(code: 'works')
        services_type = MarketType.find_or_create_by!(code: 'services')
        market.market_type_codes = %w[works services]
        market.save!
        create(:lot, public_market: market, name: 'Gros œuvre',    market_type: works_type)
        create(:lot, public_market: market, name: 'Charpente',     market_type: works_type)
        create(:lot, public_market: market, name: 'Prestations SI', market_type: services_type)
      end
    end
  end
end
