# frozen_string_literal: true

class Lot < ApplicationRecord
  belongs_to :public_market
  belongs_to :platform_market_type, class_name: 'MarketType', optional: true
  belongs_to :market_type, class_name: 'MarketType', optional: true
  has_many :market_application_lots, dependent: :destroy
  has_many :market_applications, through: :market_application_lots

  CPV_CODE_FORMAT = /\A\d{8}-\d\z/

  validates :name, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :cpv_code, format: { with: CPV_CODE_FORMAT, message: :invalid_cpv_code }, allow_blank: true

  before_validation :set_default_position, on: :create

  scope :ordered, -> { order(:position) }

  def effective_market_type
    market_type || platform_market_type
  end

  private

  def set_default_position
    return unless position.nil? || position.zero?

    self.position = self.class.where(public_market:).maximum(:position).to_i + 1
  end
end
