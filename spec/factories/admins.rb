FactoryBot.define do
  factory :admin do
    initialize_with { Admin.find_or_create_by(email: email) }

    email { 'admin@voie-rapide.gouv.fr' }
    password { 'password123' }
    password_confirmation { 'password123' }
  end
end
