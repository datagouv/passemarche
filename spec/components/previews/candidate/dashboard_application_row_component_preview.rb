# frozen_string_literal: true

# @label Dashboard Application Row Component
# @logical_path candidate
class Candidate::DashboardApplicationRowComponentPreview < Lookbook::Preview
  # @label Individuelle - en cours
  def individual_in_progress
    public_market = data.public_market
    render_for(data.individual(public_market:), public_market)
  end

  # @label Individuelle - transmise à la plateforme
  def individual_submitted
    public_market = data.public_market
    render_for(data.individual(public_market:, completed_at: Time.zone.local(2026, 10, 21, 10)), public_market)
  end

  # @label Individuelle - date limite dépassée
  def individual_deadline_passed
    public_market = data.public_market(deadline: 1.day.ago)
    render_for(data.individual(public_market:), public_market)
  end

  # @label Mandataire - en cours
  def mandataire_in_progress
    public_market = data.public_market
    render_for(data.mandataire(public_market:), public_market)
  end

  # @label Mandataire - groupement transmis
  def mandataire_submitted
    public_market = data.public_market
    render_for(data.mandataire(public_market:, submitted_at: Time.zone.local(2026, 10, 22, 10)), public_market)
  end

  # @label Co-traitant - en cours
  def co_traitant_in_progress
    public_market = data.public_market
    render_for(data.co_traitant(public_market:), public_market)
  end

  # @label Co-traitant - transmise au mandataire
  def co_traitant_sent_to_mandataire
    public_market = data.public_market
    render_for(data.co_traitant(public_market:, completed_at: Time.zone.local(2026, 10, 19, 10)), public_market)
  end

  # @label Co-traitant - groupement transmis sans sa part
  def co_traitant_grouping_submitted_without_its_part
    public_market = data.public_market
    render_for(data.co_traitant(public_market:, submitted_at: Time.zone.local(2026, 10, 22, 10)), public_market)
  end

  # @label Co-traitant - date limite dépassée
  def co_traitant_deadline_passed
    public_market = data.public_market(deadline: 1.day.ago)
    render_for(data.co_traitant(public_market:), public_market)
  end

  private

  def data
    Candidate::DashboardPreviewData
  end

  def render_for(market_application, public_market)
    render Candidate::DashboardApplicationRowComponent.new(
      application: Candidate::DashboardApplicationPresenter.new(market_application, public_market:)
    )
  end
end
