# frozen_string_literal: true

class Grouping::DashboardMembersTableComponent < ViewComponent::Base
  def initialize(presenter:, market_application:)
    @presenter = presenter
    @market_application = market_application
  end

  private

  attr_reader :presenter, :market_application

  def members
    presenter.members
  end
end
