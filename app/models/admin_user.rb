class AdminUser < ApplicationRecord
  self.table_name = 'admins'

  devise :database_authenticatable, :validatable

  enum :role, { lecteur: 0, admin: 1 }

  def can_modify?
    admin?
  end
end
