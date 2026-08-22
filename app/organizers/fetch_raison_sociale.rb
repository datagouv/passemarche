# frozen_string_literal: true

class FetchRaisonSociale < ApplicationOrganizer
  organize FetchRaisonSociale::MakeRequest,
    FetchRaisonSociale::ExtractName
end
