# frozen_string_literal: true

class GroupingMemberRemovalMailerPreview < ActionMailer::Preview
  def removed
    removal = latest_co_traitant_removal ||
              raise('No removed co-traitant with an existing grouping found to preview this mailer. ' \
                    'Remove a co-traitant from a grouping first.')

    GroupingMemberRemovalMailer.removed(removal)
  end

  private

  def latest_co_traitant_removal
    PaperTrail::Version.where(item_type: 'GroupingMember', event: 'destroy').order(id: :desc).find do |version|
      removed_member = version.reify
      removed_member.co_traitant? && removed_member.grouping.present?
    end
  end
end
