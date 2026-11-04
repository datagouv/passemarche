# frozen_string_literal: true

module Candidate
  class GroupingInvitationsController < ::ApplicationController
    include Candidate::GroupementFeatureGuard

    def show
      @grouping_member = GroupingMember.find_by(invitation_token: params[:token])
      return render_missing_member if @grouping_member.nil?
      return render_error_page(:grouping_invitation_expired, status: :gone) if @grouping_member.invitation_expired?

      @invitation_token = @grouping_member.invitation_token
      @market_application = @grouping_member.market_application
      render 'candidate/sessions/new'
    end

    private

    def render_missing_member
      removed_member = GroupingMember.removed_with_invitation_token(params[:token])
      return render_error_page(:grouping_invitation_removed, status: :gone) if removed_member&.grouping

      render_error_page(:grouping_invitation_not_found, status: :not_found)
    end
  end
end
