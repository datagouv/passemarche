# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OAuth Token', type: :request do
  include ActiveSupport::Testing::TimeHelpers
  let(:editor) do
    Editor.create!(
      name: 'Test Editor',
      client_id: 'test_client_id',
      client_secret: 'test_client_secret',
      authorized: true,
      active: true
    )
  end

  before do
    editor.ensure_doorkeeper_application!
  end

  describe 'POST /oauth/token' do
    context 'with valid client credentials' do
      it 'returns an access token with default scope' do
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: editor.client_id,
          client_secret: editor.client_secret
        }

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['access_token']).to be_present
        expect(json_response['token_type']).to eq('Bearer')
        expect(json_response['expires_in']).to eq(86_400) # 24 hours
        expect(json_response['scope']).to eq('api_access')
        expect(json_response['created_at']).to be_present
      end

      it 'returns an access token with specific scope' do
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: editor.client_id,
          client_secret: editor.client_secret,
          scope: 'api_read'
        }

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['scope']).to eq('api_read')
      end

      it 'returns an access token with multiple scopes' do
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: editor.client_id,
          client_secret: editor.client_secret,
          scope: 'api_read api_write'
        }

        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        expect(json_response['scope']).to eq('api_read api_write')
      end

      it 'revokes previous token when requesting a new one' do
        # Get first token
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: editor.client_id,
          client_secret: editor.client_secret
        }

        first_token = JSON.parse(response.body)['access_token']
        expect(first_token).to be_present

        # Get second token
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: editor.client_id,
          client_secret: editor.client_secret
        }

        second_token = JSON.parse(response.body)['access_token']

        # Verify token revocation behavior (per revoke_previous_client_credentials_token config)
        expect(Doorkeeper::AccessToken.find_by(token: first_token)).to be_revoked
        expect(Doorkeeper::AccessToken.find_by(token: second_token)).not_to be_revoked
      end
    end

    context 'with invalid client credentials' do
      it 'returns unauthorized error for wrong client_id' do
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: 'invalid_id',
          client_secret: editor.client_secret
        }

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('invalid_client')
        expect(json_response['error_description']).to be_present
      end

      it 'returns unauthorized error for wrong client_secret' do
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: editor.client_id,
          client_secret: 'invalid_secret'
        }

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('invalid_client')
      end

      it 'returns unauthorized error for both wrong credentials' do
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: 'invalid_id',
          client_secret: 'invalid_secret'
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with unauthorized editor' do
      let(:unauthorized_editor) do
        Editor.create!(
          name: 'Unauthorized Editor',
          client_id: 'unauthorized_client',
          client_secret: 'unauthorized_secret',
          authorized: false,
          active: true
        )
      end

      before do
        unauthorized_editor.ensure_doorkeeper_application!
      end

      it 'returns unauthorized error' do
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: unauthorized_editor.client_id,
          client_secret: unauthorized_editor.client_secret
        }

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('invalid_client')
      end
    end

    context 'with inactive editor' do
      let(:inactive_editor) do
        Editor.create!(
          name: 'Inactive Editor',
          client_id: 'inactive_client',
          client_secret: 'inactive_secret',
          authorized: true,
          active: false
        )
      end

      before do
        inactive_editor.ensure_doorkeeper_application!
      end

      it 'returns unauthorized error' do
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: inactive_editor.client_id,
          client_secret: inactive_editor.client_secret
        }

        expect(response).to have_http_status(:unauthorized)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('invalid_client')
      end
    end

    context 'with missing parameters' do
      it 'returns error when grant_type is missing' do
        post '/oauth/token', params: {
          client_id: editor.client_id,
          client_secret: editor.client_secret
        }

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('invalid_request')
        expect(json_response['error_description']).to be_present
      end

      it 'returns error when client_id is missing' do
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_secret: editor.client_secret
        }

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns error when client_secret is missing' do
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: editor.client_id
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with invalid grant type' do
      it 'returns unsupported_grant_type error' do
        post '/oauth/token', params: {
          grant_type: 'authorization_code',
          client_id: editor.client_id,
          client_secret: editor.client_secret
        }

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('unsupported_grant_type')
      end

      it 'returns error for password grant type' do
        post '/oauth/token', params: {
          grant_type: 'password',
          client_id: editor.client_id,
          client_secret: editor.client_secret,
          username: 'user',
          password: 'pass'
        }

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('unsupported_grant_type')
      end
    end

    context 'with invalid scope' do
      it 'returns invalid_scope error for unknown scope' do
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: editor.client_id,
          client_secret: editor.client_secret,
          scope: 'invalid_scope'
        }

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('invalid_scope')
        expect(json_response['error_description']).to be_present
      end

      it 'returns invalid_scope error for mixed valid and invalid scopes' do
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: editor.client_id,
          client_secret: editor.client_secret,
          scope: 'api_read invalid_scope'
        }

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('invalid_scope')
      end
    end

    context 'with content type variations' do
      it 'accepts application/x-www-form-urlencoded' do
        post '/oauth/token',
             params: {
               grant_type: 'client_credentials',
               client_id: editor.client_id,
               client_secret: editor.client_secret
             },
             headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }

        expect(response).to have_http_status(:ok)
      end

      it 'accepts form parameters without explicit content type' do
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: editor.client_id,
          client_secret: editor.client_secret
        }

        expect(response).to have_http_status(:ok)
      end
    end

    context 'token expiration and lifecycle' do
      it 'creates token with correct expiration time' do
        travel_to Time.current do
          post '/oauth/token', params: {
            grant_type: 'client_credentials',
            client_id: editor.client_id,
            client_secret: editor.client_secret
          }

          token = JSON.parse(response.body)['access_token']
          access_token = Doorkeeper::AccessToken.find_by(token: token)

          expect(access_token.expires_at.to_i).to eq(24.hours.from_now.to_i)
          expect(access_token.expires_in).to eq(86_400)
        end
      end

      it 'allows multiple tokens with different scopes for same client' do
        # Get token with api_read scope
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: editor.client_id,
          client_secret: editor.client_secret,
          scope: 'api_read'
        }

        read_token = JSON.parse(response.body)['access_token']

        # Get token with api_write scope
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: editor.client_id,
          client_secret: editor.client_secret,
          scope: 'api_write'
        }

        write_token = JSON.parse(response.body)['access_token']

        # With different scopes, tokens are treated separately
        # Only tokens with same scope/client combination get revoked
        expect(read_token).not_to eq(write_token)

        # Verify both tokens are stored correctly
        read_access_token = Doorkeeper::AccessToken.find_by(token: read_token)
        write_access_token = Doorkeeper::AccessToken.find_by(token: write_token)

        expect(read_access_token).to be_present
        expect(write_access_token).to be_present
        expect(read_access_token.scopes.to_s).to eq('api_read')
        expect(write_access_token.scopes.to_s).to eq('api_write')
      end
    end

    context 'performance and edge cases' do
      it 'handles rapid sequential token requests' do
        tokens = []

        5.times do
          post '/oauth/token', params: {
            grant_type: 'client_credentials',
            client_id: editor.client_id,
            client_secret: editor.client_secret
          }

          expect(response).to have_http_status(:ok)
          tokens << JSON.parse(response.body)['access_token']
        end

        # Verify token revocation behavior - all tokens except the last should be revoked
        tokens[0...-1].each do |token|
          expect(Doorkeeper::AccessToken.find_by(token: token)).to be_revoked
        end
        expect(Doorkeeper::AccessToken.find_by(token: tokens.last)).not_to be_revoked
      end

      it 'handles special characters in client credentials' do
        special_editor = Editor.create!(
          name: 'Special Editor',
          client_id: 'client-id_with.special~chars!',
          client_secret: 'secret$with#special&chars=',
          authorized: true,
          active: true
        )
        special_editor.ensure_doorkeeper_application!

        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: special_editor.client_id,
          client_secret: special_editor.client_secret
        }

        expect(response).to have_http_status(:ok)
      end
    end

    context 'security considerations' do
      it 'does not leak information about non-existent clients' do
        # Both should return same error to prevent client enumeration
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: 'non_existent',
          client_secret: 'wrong_secret'
        }

        error1 = JSON.parse(response.body)

        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: editor.client_id,
          client_secret: 'wrong_secret'
        }

        error2 = JSON.parse(response.body)

        expect(error1['error']).to eq(error2['error'])
        expect(error1['error']).to eq('invalid_client')
      end

      it 'rate limits token requests (if implemented)' do
        skip 'Rate limiting not yet implemented'

        # Make many requests rapidly
        20.times do
          post '/oauth/token', params: {
            grant_type: 'client_credentials',
            client_id: editor.client_id,
            client_secret: editor.client_secret
          }
        end

        # Should eventually get rate limited
        expect(response).to have_http_status(:too_many_requests)
      end
    end
  end

  describe 'Token refresh strategy' do
    context 'since client_credentials flow has no refresh tokens' do
      it 'requires getting a new token when current expires' do
        # Get initial token
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: editor.client_id,
          client_secret: editor.client_secret
        }

        initial_token = JSON.parse(response.body)['access_token']

        # Simulate token expiration by updating created_at and expires_in
        access_token = Doorkeeper::AccessToken.find_by(token: initial_token)
        access_token.update!(created_at: 25.hours.ago, expires_in: 86_400)

        # Must request new token
        post '/oauth/token', params: {
          grant_type: 'client_credentials',
          client_id: editor.client_id,
          client_secret: editor.client_secret
        }

        new_token = JSON.parse(response.body)['access_token']
        expect(new_token).not_to eq(initial_token)
      end

      it 'does not support refresh_token grant type' do
        post '/oauth/token', params: {
          grant_type: 'refresh_token',
          refresh_token: 'any_token',
          client_id: editor.client_id,
          client_secret: editor.client_secret
        }

        expect(response).to have_http_status(:bad_request)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('unsupported_grant_type')
      end
    end
  end

  describe 'Token usage validation' do
    let(:valid_token) do
      post '/oauth/token', params: {
        grant_type: 'client_credentials',
        client_id: editor.client_id,
        client_secret: editor.client_secret
      }
      JSON.parse(response.body)['access_token']
    end

    it 'stores the correct application association' do
      token = Doorkeeper::AccessToken.find_by(token: valid_token)
      expect(token.application.uid).to eq(editor.client_id)
      expect(token.application.name).to eq(editor.name)
    end

    it 'stores the correct scopes' do
      post '/oauth/token', params: {
        grant_type: 'client_credentials',
        client_id: editor.client_id,
        client_secret: editor.client_secret,
        scope: 'api_read api_write'
      }

      token = JSON.parse(response.body)['access_token']
      access_token = Doorkeeper::AccessToken.find_by(token: token)

      expect(access_token.scopes.to_a).to contain_exactly('api_read', 'api_write')
    end
  end
end
