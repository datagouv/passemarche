# frozen_string_literal: true

class Grouping::CompositionMembersTableComponent < ViewComponent::Base
  def initialize(grouping:, market_application:, editable:)
    @grouping = grouping
    @market_application = market_application
    @editable = editable
  end

  private

  attr_reader :grouping, :market_application

  def editable?
    @editable
  end

  def members
    grouping.grouping_members.order(:role)
  end

  def removable?(member)
    member.co_traitant? && !member.status_completed?
  end
end
