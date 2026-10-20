# frozen_string_literal: true

class GroupingMemberCompletionMailerPreview < ActionMailer::Preview
  def completed
    grouping_member = GroupingMember.co_traitant.order(id: :desc).first ||
                      raise('No co_traitant GroupingMember found to preview this mailer. Seed some grouping data first.')
    mandataire_application = grouping_member.grouping.mandataire_market_application

    GroupingMemberCompletionMailer.completed(
      grouping_member,
      mandataire_application.user&.email || 'mandataire@example.com',
      Rails.application.routes.url_helpers.grouping_dashboard_candidate_market_application_url(mandataire_application.identifier)
    )
  end
end
