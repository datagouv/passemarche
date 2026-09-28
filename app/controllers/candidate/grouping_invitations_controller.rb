# frozen_string_literal: true

module Candidate
  class GroupingInvitationsController < ::ApplicationController
    include Candidate::GroupementFeatureGuard

    def show
      @grouping_member = GroupingMember.find_by(invitation_token: params[:token])
      return render plain: "Cette invitation n'a pas été trouvée", status: :not_found if @grouping_member.nil?

      render :expired, status: :gone if @grouping_member.invitation_expired?
    end
  end
end
