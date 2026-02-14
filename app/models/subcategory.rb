# frozen_string_literal: true

class Subcategory < ApplicationRecord
  belongs_to :category
  has_many :market_attributes, dependent: :restrict_with_error

  validates :key, presence: true, uniqueness: { scope: :category_id }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :buyer_label, :candidate_label, presence: true

  scope :active, -> { where(deleted_at: nil) }
  scope :ordered, -> { order(:position) }

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def active?
    deleted_at.nil?
  end
end
