# frozen_string_literal: true

class FetchFntpDataJob < ApplicationJob
  include ApiFetchable

  def self.api_name
    'fntp'
  end

  def self.api_service
    Fntp
  end
end
