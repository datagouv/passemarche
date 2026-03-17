# frozen_string_literal: true

module CandidateAuthHelper
  include FactoryBot::Syntax::Methods
  include Rails.application.routes.url_helpers

  def authenticate_as_candidate_for(market_application)
    user = create(:user, authentication_token_sent_at: Time.current)
    token = user.generate_token_for(:magic_link)
    visit verify_candidate_sessions_path(
      token:,
      market_application_id: market_application.identifier
    )
  end
end

World(CandidateAuthHelper)
