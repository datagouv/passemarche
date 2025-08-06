# frozen_string_literal: true

class Editor < ApplicationRecord
  has_many :public_markets, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :client_id, presence: true, uniqueness: true
  validates :client_secret, presence: true

  scope :authorized, -> { where(authorized: true) }
  scope :active, -> { where(active: true) }
  scope :authorized_and_active, -> { authorized.active }

  def authorized_and_active?
    authorized? && active?
  end

  def doorkeeper_application
    @doorkeeper_application ||= CustomDoorkeeperApplication.find_by(uid: client_id)
  end

  def ensure_doorkeeper_application!
    EditorSyncService.call(self)
  end

  def sync_to_doorkeeper!
    EditorUpdateSyncService.call(self)
  end
end
