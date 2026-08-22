# frozen_string_literal: true

module Candidate
  class GroupingInvitationsController < ::ApplicationController
    def show
      @grouping_member = GroupingMember.find_by(invitation_token: params[:token])
      render plain: "Cette invitation n'a pas été trouvée", status: :not_found if @grouping_member.nil?
    end
  end
end
