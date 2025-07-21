# frozen_string_literal: true

require 'httparty'
require 'json'

class FastTrackClient
  include HTTParty

  def initialize(client_id, client_secret, base_url)
    @client_id = client_id
    @client_secret = client_secret
    @base_url = base_url
  end

  def authenticate
    response = self.class.post(
      "#{@base_url}/oauth/token",
      body: {
        grant_type: 'client_credentials',
        client_id: @client_id,
        client_secret: @client_secret,
        scope: 'api_access'
      },
      headers: {
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
    )

    raise "Authentication failed: #{response.code} - #{response.message}" unless response.success?

    response.parsed_response
  end

  def test_api_access(access_token)
    response = self.class.get(
      "#{@base_url}/api/v1/test",
      headers: {
        'Authorization' => "Bearer #{access_token}",
        'Content-Type' => 'application/json'
      }
    )

    raise "API test failed: #{response.code} - #{response.message}" unless response.success?

    response.parsed_response
  end
end
