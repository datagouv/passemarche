# frozen_string_literal: true

module Candidate
  class GroupingDashboardsController < Candidate::ApplicationController
    include Candidate::GroupementFeatureGuard
    include Candidate::MandataireGroupingGuard
    include Candidate::WizardRoutable

    before_action :redirect_unless_composition_confirmed

    def show
      @presenter = presenter
    end

    def regenerate_invitation_link
      member = grouping.grouping_members.co_traitant.find(params[:id])
      Candidate::RegenerateInvitationLink.call(grouping_member: member, notify: params[:notify] == 'true')

      render turbo_stream: turbo_stream.replace(
        "grouping_member_actions_#{member.id}",
        partial: 'candidate/grouping_dashboards/member_actions',
        locals: { member:, market_application: @market_application, presenter: }
      )
    rescue ActiveRecord::RecordNotFound
      render plain: "Le membre du groupement recherché n'a pas été trouvé", status: :not_found
    end

    private

    def redirect_unless_composition_confirmed
      return if grouping.composition_confirmed?

      redirect_to next_required_wizard_step_path(@market_application)
    end

    def presenter
      @presenter ||= Candidate::GroupingDashboardPresenter.new(@market_application, grouping:)
    end
  end
end
