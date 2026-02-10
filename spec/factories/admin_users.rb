FactoryBot.define do
  factory :admin_user do
    initialize_with { AdminUser.find_or_create_by(email:) }

    email { 'admin@voie-rapide.gouv.fr' }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { :admin }

    trait :lecteur do
      email { 'lecteur@voie-rapide.gouv.fr' }
      role { :lecteur }
    end

    trait :admin do
      role { :admin }
    end
  end
end
