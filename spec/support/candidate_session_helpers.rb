# frozen_string_literal: true

module CandidateSessionHelpers
  def sign_in_as_candidate(user, market_application)
    market_application.update!(user:) unless market_application.user_id
    user.update!(authentication_token_sent_at: Time.current)
    token = user.generate_token_for(:magic_link)
    if respond_to?(:visit)
      visit verify_candidate_sessions_path(token:, market_application_id: market_application.identifier)
    else
      get verify_candidate_sessions_path, params: { token:, market_application_id: market_application.identifier }
    end
  end
end

RSpec.configure do |config|
  config.include CandidateSessionHelpers, type: :request
  config.include CandidateSessionHelpers, type: :feature
end
