# frozen_string_literal: true

module Candidate
  class GroupingDashboardsController < Candidate::ApplicationController
    include Candidate::GroupementFeatureGuard
    include Candidate::MandataireGroupingGuard

    def show
      @presenter = presenter
    end

    def regenerate_invitation_link
      member = grouping.grouping_members.find(params[:id])
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

    def presenter
      @presenter ||= Candidate::GroupingDashboardPresenter.new(@market_application)
    end
  end
end
