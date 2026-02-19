# frozen_string_literal: true

class MarketAttributeResponse::Shared::DocumentItemComponent < ViewComponent::Base
  attr_reader :document, :market_application, :context, :show_size

  def initialize(document:, market_application:, context: :web, show_size: true, naming_service: nil)
    @document = document
    @market_application = market_application
    @context = context
    @show_size = show_size
    @naming_service = naming_service
  end

  def display_name
    return system_filename if context == :buyer

    original_filename
  end

  def file_size
    helpers.number_to_human_size(document.byte_size)
  end

  def malware_badge
    helpers.dsfr_malware_badge(document, class: 'fr-ml-1w')
  end

  private

  def naming_service
    @naming_service ||= DocumentNamingService.new(market_application)
  end

  def original_filename
    naming_service.original_filename_for(document)
  end

  def system_filename
    naming_service.system_filename_for(document)
  end
end
