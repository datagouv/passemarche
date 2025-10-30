# frozen_string_literal: true

class FetchDgfipDataJob < ApplicationJob
  include ApiFetchable

  def self.api_name
    'attestations_fiscales'
  end

  def self.api_service
    Dgfip
  end
end
