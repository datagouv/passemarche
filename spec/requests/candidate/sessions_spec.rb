# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::Sessions', type: :request do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }
  let(:user) { create(:user, email: 'candidat@example.com') }
  let(:valid_siret) { market_application.siret }

  before do
    allow(SiretValidator).to receive(:valid?).and_call_original
    allow(SiretValidator).to receive(:valid?).with(valid_siret).and_return(true)
  end

  describe 'GET #new' do
    it 'returns ok' do
      get new_candidate_sessions_path

      expect(response).to have_http_status(:ok)
    end

    context 'when market_application_id is provided' do
      it 'returns ok' do
        get new_candidate_sessions_path, params: { market_application_id: market_application.identifier }

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when market_application_id is unknown' do
      it 'returns ok' do
        get new_candidate_sessions_path, params: { market_application_id: 'VR-UNKNOWN' }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'POST #create' do
    context 'when inputs are valid' do
      it 'redirects to sent path' do
        post candidate_sessions_path,
          params: { email: user.email, siret: valid_siret, market_application_id: market_application.identifier }

        expect(response).to redirect_to(sent_candidate_sessions_path)
      end

      it 'sends the magic link email' do
        expect do
          post candidate_sessions_path,
            params: { email: user.email, siret: valid_siret, market_application_id: market_application.identifier }
        end.to have_enqueued_mail(AuthMailer, :magic_link)
      end
    end

    context 'when email is invalid' do
      it 'returns unprocessable_content' do
        post candidate_sessions_path,
          params: { email: 'invalid', siret: valid_siret, market_application_id: market_application.identifier }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'preserves market_application_id in the re-rendered form' do
        post candidate_sessions_path,
          params: { email: 'invalid', siret: valid_siret, market_application_id: market_application.identifier }

        expect(response.body).to include(market_application.identifier)
      end
    end

    context 'when SIRET is invalid' do
      it 'returns unprocessable_content' do
        post candidate_sessions_path, params: { email: user.email, siret: 'NOT-A-SIRET', market_application_id: market_application.identifier }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when reconnecting with matching email' do
      before { market_application.update!(user:) }

      it 'stores reconnection_market_name in session' do
        post candidate_sessions_path,
          params: { email: user.email, siret: valid_siret, market_application_id: market_application.identifier }

        expect(session[:reconnection_market_name]).to eq(market_application.public_market.name)
      end

      it 'redirects to sent path' do
        post candidate_sessions_path,
          params: { email: user.email, siret: valid_siret, market_application_id: market_application.identifier }

        expect(response).to redirect_to(sent_candidate_sessions_path)
      end
    end

    context 'when reconnecting with wrong email' do
      before { market_application.update!(user: create(:user, email: 'other@example.com')) }

      it 'returns unprocessable_content' do
        post candidate_sessions_path,
          params: { email: user.email, siret: valid_siret, market_application_id: market_application.identifier }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET /candidate/sessions/sent' do
    it 'returns ok' do
      get sent_candidate_sessions_path

      expect(response).to have_http_status(:ok)
    end

    context 'when reconnection_market_name was set by a reconnection login' do
      before do
        market_application.update!(user:)
        post candidate_sessions_path,
          params: { email: user.email, siret: valid_siret, market_application_id: market_application.identifier }
      end

      it 'clears reconnection_market_name from session' do
        get sent_candidate_sessions_path

        expect(session[:reconnection_market_name]).to be_nil
      end
    end
  end

  describe 'GET /candidate/sessions/verify' do
    let(:token) do
      user.update!(authentication_token_sent_at: Time.current)
      user.generate_token_for(:magic_link)
    end

    context 'when token is valid and market_application is accessible' do
      it 'stores user_id in session' do
        get verify_candidate_sessions_path,
          params: { token:, market_application_id: market_application.identifier }

        expect(session[:user_id]).to eq(user.id)
      end

      it 'associates user to market_application on first access' do
        expect do
          get verify_candidate_sessions_path,
            params: { token:, market_application_id: market_application.identifier }
        end.to change { market_application.reload.user_id }.from(nil).to(user.id)
      end

      it 'redirects to return_to url if stored' do
        return_to = step_candidate_market_application_path(market_application.identifier, :company_identification)
        get return_to

        get verify_candidate_sessions_path,
          params: { token:, market_application_id: market_application.identifier }

        expect(response).to redirect_to(return_to)
      end

      it 'redirects to first step if no return_to stored' do
        get verify_candidate_sessions_path,
          params: { token:, market_application_id: market_application.identifier }

        expect(response).to redirect_to(
          step_candidate_market_application_path(market_application.identifier, :company_identification)
        )
      end
    end

    context 'when reconnecting (market_application already assigned to user)' do
      before { market_application.update!(user:) }

      it 'stores user_id in session' do
        get verify_candidate_sessions_path,
          params: { token:, market_application_id: market_application.identifier }

        expect(session[:user_id]).to eq(user.id)
      end

      it 'does not change market_application user' do
        expect do
          get verify_candidate_sessions_path,
            params: { token:, market_application_id: market_application.identifier }
        end.not_to change { market_application.reload.user_id }
      end

      it 'redirects to first step of application' do
        get verify_candidate_sessions_path,
          params: { token:, market_application_id: market_application.identifier }

        expect(response).to redirect_to(
          step_candidate_market_application_path(market_application.identifier, :company_identification)
        )
      end
    end

    context 'when reconnecting to an already completed application' do
      before do
        market_application.update!(user:, completed_at: Time.current, sync_status: :sync_completed)
      end

      it 'redirects to sync status page' do
        get verify_candidate_sessions_path,
          params: { token:, market_application_id: market_application.identifier }

        expect(response).to redirect_to(candidate_sync_status_path(market_application.identifier))
      end
    end

    context 'when market has lots and no lots are selected' do
      let(:market_with_lots) { create(:public_market, :completed, editor:) }
      let(:application_with_lots) { create(:market_application, public_market: market_with_lots, siret: '73282932000074') }
      let(:token_for_lots) do
        user.update!(authentication_token_sent_at: Time.current)
        user.generate_token_for(:magic_link)
      end

      before { create(:lot, public_market: market_with_lots, name: 'Lot 1') }

      it 'redirects to lot selection' do
        get verify_candidate_sessions_path,
          params: { token: token_for_lots, market_application_id: application_with_lots.identifier }

        expect(response).to redirect_to(
          lot_selection_candidate_market_application_path(application_with_lots.identifier)
        )
      end
    end

    context 'when market has lots and lots are already selected' do
      let(:market_with_lots) { create(:public_market, :completed, editor:) }
      let(:application_with_lots) { create(:market_application, public_market: market_with_lots, siret: '73282932000074') }
      let(:token_for_lots) do
        user.update!(authentication_token_sent_at: Time.current)
        user.generate_token_for(:magic_link)
      end

      before do
        lot = create(:lot, public_market: market_with_lots, name: 'Lot 1')
        application_with_lots.lots << lot
      end

      it 'redirects to lot selection' do
        get verify_candidate_sessions_path,
          params: { token: token_for_lots, market_application_id: application_with_lots.identifier }

        expect(response).to redirect_to(
          lot_selection_candidate_market_application_path(application_with_lots.identifier)
        )
      end
    end

    context 'when market_application is already completed' do
      before { market_application.update!(user:) && market_application.complete! }

      it 'redirects to sync status' do
        get verify_candidate_sessions_path,
          params: { token:, market_application_id: market_application.identifier }

        expect(response).to redirect_to(
          candidate_sync_status_path(market_application.identifier)
        )
      end
    end

    context 'when token is invalid' do
      it 'redirects to sessions new with alert' do
        get verify_candidate_sessions_path, params: { token: 'invalid_token', market_application_id: market_application.identifier }

        expect(response).to redirect_to(new_candidate_sessions_path(market_application_id: market_application.identifier))
        expect(flash[:alert]).to eq(I18n.t('candidate.sessions.invalid_token'))
      end
    end

    context 'when market_application is not found' do
      it 'redirects to sessions new with alert' do
        get verify_candidate_sessions_path, params: { token:, market_application_id: 'VR-UNKNOWN' }

        expect(response).to redirect_to(new_candidate_sessions_path(market_application_id: 'VR-UNKNOWN'))
        expect(flash[:alert]).to eq(I18n.t('candidate.sessions.invalid_token'))
      end
    end
  end

  describe 'DELETE /candidate/sessions' do
    before { sign_in_as_candidate(user, market_application) }

    it 'clears session' do
      delete candidate_sessions_path

      expect(session[:user_id]).to be_nil
    end

    it 'redirects to root' do
      delete candidate_sessions_path

      expect(response).to redirect_to(root_path)
    end
  end
end
