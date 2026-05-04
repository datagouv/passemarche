# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::ApplicationConsultations', type: :request do
  let(:editor) { create(:editor) }
  let(:user) { create(:user) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:application) { create(:market_application, :completed, public_market:, user:) }

  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  describe 'GET /candidate/market_applications/:identifier/consultation' do
    context 'when not authenticated' do
      it 'renders the login form' do
        get consultation_candidate_market_application_path(application.identifier)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t('candidate.sessions.new.title'))
      end
    end

    context 'when authenticated' do
      before { sign_in_as_candidate(user, application) }

      it 'returns ok' do
        get consultation_candidate_market_application_path(application.identifier)

        expect(response).to have_http_status(:ok)
      end

      it 'displays the market name' do
        get consultation_candidate_market_application_path(application.identifier)

        expect(response.body).to include(CGI.escapeHTML(public_market.name))
      end

      context 'when the application is not completed' do
        let(:application) { create(:market_application, public_market:, user:) }

        it 'redirects to the dashboard' do
          get consultation_candidate_market_application_path(application.identifier)

          expect(response).to redirect_to(candidate_dashboard_path)
        end
      end

      context 'when the application belongs to another user' do
        let(:other_user) { create(:user) }
        let(:other_application) { create(:market_application, :completed, public_market:, user: other_user) }

        it 'renders the login form' do
          get consultation_candidate_market_application_path(other_application.identifier)

          expect(response).to have_http_status(:ok)
          expect(response.body).to include(I18n.t('candidate.sessions.new.title'))
        end
      end
    end
  end
end
