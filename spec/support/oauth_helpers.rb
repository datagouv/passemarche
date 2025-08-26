# frozen_string_literal: true

module OAuthHelpers
  def oauth_access_token_for(editor, scope: 'api_access')
    editor.ensure_doorkeeper_application!

    post '/oauth/token', params: {
      grant_type: 'client_credentials',
      client_id: editor.client_id,
      client_secret: editor.client_secret,
      scope:
    }

    response.parsed_body['access_token']
  end
end

RSpec.configure do |config|
  config.include OAuthHelpers, type: :request
end
