# frozen_string_literal: true

class Candidate::DashboardApplicationRowComponent < ViewComponent::Base
  def initialize(application:)
    @application = application
  end

  private

  attr_reader :application

  def actions
    @actions ||= application.actions
  end

  def mandataire_label
    @mandataire_label ||= application.mandataire_label
  end
end
