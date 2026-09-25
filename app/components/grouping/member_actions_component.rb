# frozen_string_literal: true

class Grouping::MemberActionsComponent < ViewComponent::Base
  def initialize(member:, market_application:, presenter:)
    @member = member
    @market_application = market_application
    @presenter = presenter
  end

  private

  attr_reader :member, :market_application, :presenter

  def actions
    presenter.member_actions(member)
  end

  def member_application_identifier
    presenter.member_application_identifier(member)
  end

  def invitation_sent?
    presenter.member_invitation_sent?(member)
  end

  def invitation_url
    candidate_grouping_invitation_url(presenter.member_invitation_token(member))
  end
end
