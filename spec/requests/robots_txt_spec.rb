# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GET /robots.txt', type: :request do
  describe 'in production environment' do
    before do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
    end

    it 'returns a permissive robots.txt' do
      get '/robots.txt'

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('text/plain')
      expect(response.body).to include('User-agent: *')
      expect(response.body).to include('Allow: /')
      expect(response.body).not_to include('Disallow')
    end
  end

  describe 'in non-production environment' do
    it 'returns a restrictive robots.txt' do
      get '/robots.txt'

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('text/plain')
      expect(response.body).to include('User-agent: *')
      expect(response.body).to include('Disallow: /')
    end
  end
end
