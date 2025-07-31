# frozen_string_literal: true

class MarketAttribute < ApplicationRecord
  has_and_belongs_to_many :market_types
  has_and_belongs_to_many :public_markets

  validates :key, presence: true, uniqueness: true
  validates :category_key, :subcategory_key, presence: true

  enum :input_type, {
    file_upload: 0,
    text_input: 1,
    checkbox: 2
  }

  scope :required, -> { where(required: true) }
  scope :additional, -> { where(required: false) }
  scope :from_api, -> { where(from_api: true) }
  scope :active, -> { where(deleted_at: nil) }

  scope :ordered, lambda {
    order(:required, :category_key, :subcategory_key, :key)
  }

  def from_authentic_source?
    from_api?
  end
end
