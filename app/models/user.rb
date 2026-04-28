# frozen_string_literal: true

class User < ApplicationRecord
  generates_token_for :magic_link, expires_in: 30.minutes do
    authentication_token_sent_at
  end

  validates :email, presence: true,
    uniqueness: { case_sensitive: false },
    email: true

  before_save :normalize_email

  def self.find_or_create_by_email(email)
    normalized = email.to_s.downcase.strip
    find_or_create_by(email: normalized)
  end

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end
end
