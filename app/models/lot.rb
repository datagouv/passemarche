# frozen_string_literal: true

class Lot < ApplicationRecord
  belongs_to :public_market
  has_many :market_application_lots, dependent: :destroy
  has_many :market_applications, through: :market_application_lots

  validates :name, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  before_validation :set_default_position, on: :create

  scope :ordered, -> { order(:position) }

  private

  def set_default_position
    return unless position.nil? || position.zero?

    self.position = self.class.where(public_market:).maximum(:position).to_i + 1
  end
end
