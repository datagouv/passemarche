class AdminUser < ApplicationRecord
  self.table_name = 'admins'

  devise :database_authenticatable, :validatable
end
