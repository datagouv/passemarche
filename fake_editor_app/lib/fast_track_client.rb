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

  def create_public_market(access_token, market_data)
    payload = { public_market: market_data }

    response = self.class.post(
      "#{@base_url}/api/v1/public_markets",
      body: payload.to_json,
      headers: {
        'Authorization' => "Bearer #{access_token}",
        'Content-Type' => 'application/json'
      }
    )

    unless response.success?
      error_details = response.parsed_response
      error_msg = if error_details.is_a?(Hash) && error_details['errors']
                    "#{response.code} - #{error_details['errors'].join(', ')}"
                  else
                    "#{response.code} - #{response.message}"
                  end
      raise "Public market creation failed: #{error_msg}"
    end

    response.parsed_response
  end
end
