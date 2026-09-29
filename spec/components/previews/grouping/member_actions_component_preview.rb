# frozen_string_literal: true

# @label Member Actions Component
# @logical_path grouping
class Grouping::MemberActionsComponentPreview < Lookbook::Preview
  # @label Mandataire - candidature à préparer
  def mandataire_to_prepare
    member = Grouping::PreviewData.grouping.grouping_members.mandataire.first
    member.update!(status: :to_prepare)

    render_for(member)
  end

  # @label Mandataire - candidature en cours
  def mandataire_in_progress
    member = Grouping::PreviewData.grouping.grouping_members.mandataire.first
    member.update!(status: :in_progress)

    render_for(member)
  end

  # @label Mandataire - candidature terminée
  def mandataire_completed
    member = Grouping::PreviewData.grouping.grouping_members.mandataire.first
    member.update!(status: :completed)

    render_for(member)
  end

  # @label Co-traitant - invitation non envoyée
  def co_traitant_invitation_not_sent
    member = Grouping::PreviewData.co_traitant_member
    member.update!(invitation_token: nil, invitation_token_created_at: nil)

    render_for(member)
  end

  # @label Co-traitant - invitation envoyée
  def co_traitant_invitation_sent
    member = Grouping::PreviewData.co_traitant_member
    member.update!(invitation_token: SecureRandom.hex, invitation_token_created_at: Time.current)

    render_for(member)
  end

  private

  def render_for(member)
    presenter = Candidate::GroupingDashboardPresenter.new(Grouping::PreviewData.mandataire_market_application, grouping: Grouping::PreviewData.grouping)

    render(Grouping::MemberActionsComponent.new(member:, market_application: Grouping::PreviewData.mandataire_market_application, presenter:))
  end
end
