# frozen_string_literal: true

module Candidate
  class GroupingDashboardsController < Candidate::ApplicationController
    include Candidate::GroupementFeatureGuard

    prepend_before_action :find_market_application
    before_action :redirect_unless_mandataire

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

    def find_market_application
      @market_application = MarketApplication.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: "La candidature recherchée n'a pas été trouvée", status: :not_found
    end

    def redirect_unless_mandataire
      return if grouping

      redirect_to grouping_wizard_step_candidate_market_application_path(@market_application.identifier, :application_mode)
    end

    def grouping
      @grouping ||= @market_application.mandataire_grouping
    end
  end
end
