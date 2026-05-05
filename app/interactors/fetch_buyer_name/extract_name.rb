# frozen_string_literal: true

class FetchBuyerName::ExtractName < ApplicationInteractor
  def call
    body = JSON.parse(context.response.body)
    context.buyer_name = body.dig('data', 'unite_legale', 'personne_morale_attributs', 'raison_sociale')
  rescue JSON::ParserError
    context.fail!(error: 'Invalid JSON response')
  end
end
