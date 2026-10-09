# frozen_string_literal: true

module Candidate
  class GroupingInvitationsController < ::ApplicationController
    include Candidate::GroupementFeatureGuard

    def show
      @grouping_member = GroupingMember.find_by(invitation_token: params[:token])
      return render :not_found, status: :not_found if @grouping_member.nil?
      return render :expired, status: :gone if @grouping_member.invitation_expired?

      @invitation_token = @grouping_member.invitation_token
      @market_application = @grouping_member.market_application
      render 'candidate/sessions/new'
    end
  end
end
