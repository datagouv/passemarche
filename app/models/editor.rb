# frozen_string_literal: true

class Editor < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :client_id, presence: true, uniqueness: true
  validates :client_secret, presence: true

  scope :authorized, -> { where(authorized: true) }
  scope :active, -> { where(active: true) }
  scope :authorized_and_active, -> { authorized.active }

  def authorized_and_active?
    authorized? && active?
  end
end
