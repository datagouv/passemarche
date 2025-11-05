# frozen_string_literal: true

# Background job to fetch data from DGFIP Chiffres d'Affaires API
class FetchChiffresAffairesDataJob < ApplicationJob
  include ApiFetchable

  def self.api_name
    'dgfip_chiffres_affaires'
  end

  def self.api_service
    ChiffresAffaires
  end
end
