# frozen_string_literal: true

class NotifyCoTraitantsOfGroupingSubmission < ApplicationInteractor
  delegate :grouping, to: :context

  def call
    grouping.grouping_members.co_traitant.find_each do |member|
      GroupingSubmissionMailer.submitted(member).deliver_later
    end
  end
end
