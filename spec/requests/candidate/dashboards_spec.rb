# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::Dashboards', type: :request do
  let(:editor) { create(:editor) }
  let(:user) { create(:user, email: 'candidat@example.com') }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:application) { create(:market_application, public_market:, user:) }

  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  describe 'GET /candidate/dashboard' do
    context 'when not authenticated' do
      it 'renders the login form' do
        get candidate_dashboard_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t('candidate.sessions.new.title'))
      end
    end

    context 'when authenticated' do
      before { sign_in_as_candidate(user, application) }

      it 'returns ok' do
        get candidate_dashboard_path

        expect(response).to have_http_status(:ok)
      end

      it 'displays the dashboard title' do
        get candidate_dashboard_path

        expect(response.body).to include(I18n.t('candidate.dashboard.title'))
      end

      it 'does not expose other users applications' do
        other_user = create(:user, email: 'other@example.com')
        other_market = create(:public_market, :completed, editor: create(:editor), name: 'Marché confidentiel')
        create(:market_application, public_market: other_market, user: other_user)

        get candidate_dashboard_path

        expect(response.body).not_to include('Marché confidentiel')
      end
    end
  end
end
