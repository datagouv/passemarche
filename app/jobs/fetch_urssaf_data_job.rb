# frozen_string_literal: true

class FetchUrssafDataJob < ApplicationJob
  include ApiFetchable

  def self.api_name
    'urssaf_attestation_vigilance'
  end

  def self.api_service
    Urssaf
  end
end
