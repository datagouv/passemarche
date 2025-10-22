# frozen_string_literal: true

# Background job to fetch data from INSEE API
class FetchInseeDataJob < ApplicationJob
  include ApiFetchable

  def self.api_name
    'insee'
  end

  def self.api_service
    Insee
  end
end
