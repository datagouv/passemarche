# frozen_string_literal: true

class FetchActesBilansDataJob < ApplicationJob
  include ApiFetchable

  def self.api_name
    'actes_bilans'
  end

  def self.api_service
    ActesBilans
  end
end
