# frozen_string_literal: true

# @label Dashboard Members Table Component
# @logical_path grouping
class Grouping::DashboardMembersTableComponentPreview < Lookbook::Preview
  # @label Default
  def default
    Grouping::PreviewData.co_traitant_member
    market_application = Grouping::PreviewData.mandataire_market_application
    presenter = Candidate::GroupingDashboardPresenter.new(market_application, grouping: Grouping::PreviewData.grouping)

    render(Grouping::DashboardMembersTableComponent.new(presenter:, market_application:))
  end
end
