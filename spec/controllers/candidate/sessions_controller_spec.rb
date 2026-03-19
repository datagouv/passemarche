# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::SessionsController, type: :controller do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }
  let(:user) { create(:user, email: 'candidat@example.com') }
  let(:valid_siret) { market_application.siret }

  before do
    allow(SiretValidationService).to receive(:call).and_call_original
    allow(SiretValidationService).to receive(:call).with(valid_siret).and_return(true)
  end

  describe 'POST #create' do
    context 'when inputs are valid' do
      it 'redirects to sent path' do
        post :create, params: { email: user.email, siret: valid_siret }

        expect(response).to redirect_to(sent_candidate_sessions_path)
      end

      it 'sends the magic link email' do
        expect do
          post :create, params: { email: user.email, siret: valid_siret }
        end.to have_enqueued_mail(AuthMailer, :magic_link)
      end
    end

    context 'when email is invalid' do
      it 'returns unprocessable_content' do
        post :create, params: { email: 'invalid', siret: valid_siret }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context 'when SIRET is invalid' do
      before { allow(SiretValidationService).to receive(:call).with('00000000000000').and_return(false) }

      it 'returns unprocessable_content' do
        post :create, params: { email: user.email, siret: '00000000000000' }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'POST #create' do
    context 'when reconnecting with matching email' do
      before { market_application.update!(user:) }

      it 'stores reconnection_market_name in session' do
        post :create, params: { email: user.email, siret: valid_siret }

        expect(session[:reconnection_market_name]).to eq(market_application.public_market.name)
      end

      it 'redirects to sent path' do
        post :create, params: { email: user.email, siret: valid_siret }

        expect(response).to redirect_to(sent_candidate_sessions_path)
      end
    end

    context 'when reconnecting with wrong email' do
      before { market_application.update!(user: create(:user, email: 'other@example.com')) }

      it 'returns unprocessable_content' do
        post :create, params: { email: user.email, siret: valid_siret }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'GET #sent' do
    it 'returns ok' do
      get :sent

      expect(response).to have_http_status(:ok)
    end

    context 'when reconnection_market_name is in session' do
      before { session[:reconnection_market_name] = 'Marché test' }

      it 'clears reconnection_market_name from session' do
        get :sent

        expect(session[:reconnection_market_name]).to be_nil
      end
    end
  end

  describe 'GET #verify' do
    let(:token) do
      user.update!(authentication_token_sent_at: Time.current)
      user.generate_token_for(:magic_link)
    end

    context 'when token is valid and market_application is accessible' do
      it 'stores user_id in session' do
        get :verify, params: { token:, market_application_id: market_application.identifier }

        expect(session[:user_id]).to eq(user.id)
      end

      it 'associates user to market_application on first access' do
        expect do
          get :verify, params: { token:, market_application_id: market_application.identifier }
        end.to change { market_application.reload.user_id }.from(nil).to(user.id)
      end

      it 'redirects to return_to url if stored' do
        session[:return_to] = '/candidate/market_applications/VR-xxx/company_identification'

        get :verify, params: { token:, market_application_id: market_application.identifier }

        expect(response).to redirect_to('/candidate/market_applications/VR-xxx/company_identification')
      end

      it 'redirects to first step if no return_to stored' do
        get :verify, params: { token:, market_application_id: market_application.identifier }

        expect(response).to redirect_to(
          step_candidate_market_application_path(market_application.identifier, :company_identification)
        )
      end
    end

    context 'when reconnecting (market_application already assigned to user)' do
      before { market_application.update!(user:) }

      it 'stores user_id in session' do
        get :verify, params: { token:, market_application_id: market_application.identifier }

        expect(session[:user_id]).to eq(user.id)
      end

      it 'does not change market_application user' do
        expect do
          get :verify, params: { token:, market_application_id: market_application.identifier }
        end.not_to change { market_application.reload.user_id }
      end

      it 'redirects to first step of application' do
        get :verify, params: { token:, market_application_id: market_application.identifier }

        expect(response).to redirect_to(
          step_candidate_market_application_path(market_application.identifier, :company_identification)
        )
      end
    end

    context 'when token is invalid' do
      it 'redirects to root with alert' do
        get :verify, params: { token: 'invalid_token', market_application_id: market_application.identifier }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t('candidate.sessions.invalid_token'))
      end
    end

    context 'when market_application is not found' do
      it 'redirects to root with alert' do
        get :verify, params: { token:, market_application_id: 'VR-UNKNOWN' }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t('candidate.sessions.invalid_token'))
      end
    end
  end

  describe 'DELETE #destroy' do
    before { session[:user_id] = user.id }

    it 'clears session' do
      delete :destroy

      expect(session[:user_id]).to be_nil
    end

    it 'redirects to root' do
      delete :destroy

      expect(response).to redirect_to(root_path)
    end
  end
end
