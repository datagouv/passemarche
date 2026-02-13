# frozen_string_literal: true

class Category < ApplicationRecord
  has_many :subcategories, dependent: :destroy
  has_many :market_attributes, through: :subcategories

  validates :key, presence: true, uniqueness: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(deleted_at: nil) }
  scope :ordered, -> { order(:position) }

  def soft_delete!
    transaction do
      update!(deleted_at: Time.current)
      subcategories.each(&:soft_delete!)
    end
  end

  def active?
    deleted_at.nil?
  end
end
