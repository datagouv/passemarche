# frozen_string_literal: true

class Candidate::DashboardApplicationRowComponent < ViewComponent::Base
  with_collection_parameter :application

  def initialize(application:)
    @application = application
  end

  private

  attr_reader :application
end
