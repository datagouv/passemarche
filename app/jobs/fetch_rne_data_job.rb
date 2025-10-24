# frozen_string_literal: true

# Background job to fetch data from RNE API
class FetchRneDataJob < ApplicationJob
  include ApiFetchable

  def self.api_name
    'rne'
  end

  def self.api_service
    Rne
  end
end
