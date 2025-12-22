# frozen_string_literal: true

class FetchBodaccDataJob < ApplicationJob
  include ApiFetchable

  def self.api_name
    'bodacc'
  end

  def self.api_service
    Bodacc
  end
end
