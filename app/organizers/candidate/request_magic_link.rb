# frozen_string_literal: true

module Candidate
  class RequestMagicLink < ApplicationOrganizer
    organize ValidateEmailFormat,
      ValidateSiret,
      FindMarketApplication,
      FindOrCreateUser,
      GenerateAndSendMagicLink
  end
end
