# frozen_string_literal: true

# Background job to fetch data from Qualibat API
class FetchQualibatDataJob < ApplicationJob
  include ApiFetchable

  def self.api_name
    'qualibat'
  end

  def self.api_service
    Qualibat
  end
end
