# frozen_string_literal: true

class FetchRgeDataJob < ApplicationJob
  include ApiFetchable

  def self.api_name
    'rge'
  end

  def self.api_service
    Rge
  end
end
