# frozen_string_literal: true

class MarketType < ApplicationRecord
  include UniqueAssociationValidator

  has_and_belongs_to_many :market_attributes

  validates :code, presence: true, uniqueness: true
  validates_uniqueness_of_association :market_attributes

  scope :active, -> { where(deleted_at: nil) }

  def required_attributes
    market_attributes.required.active.ordered
  end

  def additional_attributes
    market_attributes.additional.active.ordered
  end
end
