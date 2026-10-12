# frozen_string_literal: true

class GroupingMemberRemovalMailerPreview < ActionMailer::Preview
  def removed
    removal = PaperTrail::Version.where(item_type: 'GroupingMember', event: 'destroy').order(id: :desc).first ||
              raise('No removed GroupingMember found to preview this mailer. Remove a co-traitant from a grouping first.')

    GroupingMemberRemovalMailer.removed(removal)
  end
end
