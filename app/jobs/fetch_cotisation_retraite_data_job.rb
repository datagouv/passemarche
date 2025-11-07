# frozen_string_literal: true

class FetchCotisationRetraiteDataJob < ApplicationJob
  include ApiFetchable

  def self.api_name
    'cotisation_retraite'
  end

  def self.api_service
    CotisationRetraite
  end

  private

  def fetch_and_process_data(market_application)
    market_application.update_api_status(self.class.api_name, status: 'processing')

    result = self.class.api_service.call(
      params: {
        siret: market_application.siret,
        siren: market_application.siret[0..8]
      },
      market_application:
    )

    handle_result(market_application, result)
  end
end
