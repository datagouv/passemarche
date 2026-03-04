# frozen_string_literal: true

module Candidate
  class RequestMagicLink < ApplicationOrganizer
    organize ValidateEmailFormat,
      ValidateSiret,
      FindMarketApplicationBySiret,
      FindOrCreateUser,
      GenerateAndSendMagicLink
  end
end
