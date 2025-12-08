# frozen_string_literal: true

class FetchCarifOrefDataJob < ApplicationJob
  include ApiFetchable

  def self.api_name
    'carif_oref'
  end

  def self.api_service
    CarifOref
  end
end
