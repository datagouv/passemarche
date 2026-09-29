# frozen_string_literal: true

# @label Composition Members Table Component
# @logical_path grouping
class Grouping::CompositionMembersTableComponentPreview < Lookbook::Preview
  # @label Editable - avec un co-traitant retirable
  def editable_with_co_traitant
    member = Grouping::PreviewData.co_traitant_member
    member.update!(status: :in_progress)

    render(Grouping::CompositionMembersTableComponent.new(grouping: Grouping::PreviewData.grouping, market_application: Grouping::PreviewData.mandataire_market_application, editable: true))
  end

  # @label Editable - sans co-traitant
  def editable_without_co_traitant
    grouping = Grouping::PreviewData.grouping
    grouping.grouping_members.co_traitant.destroy_all

    render(Grouping::CompositionMembersTableComponent.new(grouping:, market_application: Grouping::PreviewData.mandataire_market_application, editable: true))
  end

  # @label Lecture seule (page de confirmation)
  def not_editable
    member = Grouping::PreviewData.co_traitant_member
    member.update!(status: :in_progress)

    render(Grouping::CompositionMembersTableComponent.new(grouping: Grouping::PreviewData.grouping, market_application: Grouping::PreviewData.mandataire_market_application, editable: false))
  end
end
