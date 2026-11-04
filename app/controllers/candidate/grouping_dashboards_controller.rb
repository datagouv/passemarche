# frozen_string_literal: true

module Candidate
  class GroupingDashboardsController < Candidate::ApplicationController
    include Candidate::GroupementFeatureGuard
    include Candidate::GroupingMemberGuard
    include Candidate::WizardRoutable

    before_action :redirect_unless_composition_confirmed

    def show
      @presenter = presenter
    end

    private

    def redirect_unless_composition_confirmed
      return if grouping.composition_confirmed?

      redirect_to next_required_wizard_step_path(@market_application)
    end

    def presenter
      @presenter ||= Candidate::GroupingDashboardPresenter.new(@market_application, grouping:, current_member: current_grouping_member)
    end
  end
end
