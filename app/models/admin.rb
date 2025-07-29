class Admin < ApplicationRecord
  devise :database_authenticatable, :validatable
end
