# frozen_string_literal: true

# @label Dashboard Market Card Component
# @logical_path candidate
class Candidate::DashboardMarketCardComponentPreview < Lookbook::Preview
  # @label Candidature mixte (groupement + individuelle)
  def mixed
    public_market = data.public_market
    render_for(public_market, [data.individual(public_market:), data.mandataire(public_market:)])
  end

  # @label Co-traitant de deux groupements
  def co_traitant_of_two_groupings
    public_market = data.public_market
    render_for(public_market, [data.co_traitant(public_market:), data.co_traitant(public_market:)])
  end

  # @label Candidature individuelle seule
  def individual_only
    public_market = data.public_market
    render_for(public_market, [data.individual(public_market:)])
  end

  private

  def data
    Candidate::DashboardPreviewData
  end

  def render_for(public_market, market_applications)
    render Candidate::DashboardMarketCardComponent.new(
      market: Candidate::DashboardMarketPresenter.new(public_market, market_applications)
    )
  end
end
