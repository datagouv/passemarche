# frozen_string_literal: true

class FetchBuyerName < ApplicationOrganizer
  organize FetchBuyerName::MakeRequest,
    FetchBuyerName::ExtractName
end
