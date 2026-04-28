# frozen_string_literal: true

module Candidate
  class RequestMagicLink < ApplicationOrganizer
    organize ValidateEmailFormat,
      ValidateSiret,
      ResolveMarketApplicationForReconnection,
      FindOrCreateUser,
      GenerateAndSendMagicLink
  end
end
