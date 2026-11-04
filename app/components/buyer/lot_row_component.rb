# frozen_string_literal: true

class Buyer::LotRowComponent < ViewComponent::Base
  def initialize(lot:)
    @lot = lot
  end

  private

  attr_reader :lot
end
