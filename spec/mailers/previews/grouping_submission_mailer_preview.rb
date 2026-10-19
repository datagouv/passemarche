# frozen_string_literal: true

class GroupingSubmissionMailerPreview < ActionMailer::Preview
  def submitted
    grouping_member = GroupingMember.co_traitant.order(id: :desc).first ||
                      raise('No co_traitant GroupingMember found to preview this mailer. Seed some grouping data first.')

    GroupingSubmissionMailer.submitted(grouping_member)
  end
end
