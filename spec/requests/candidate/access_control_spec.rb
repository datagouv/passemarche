# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate access control', type: :request do
  let(:editor) { create(:editor) }
  let(:siret_a) { '73282932000074' }
  let(:siret_b) { '41816609600069' }

  let(:user_a) { create(:user) }
  let(:market_a) { create(:public_market, :completed, editor:, name: 'Marché candidat A') }
  let(:app_a) { create(:market_application, public_market: market_a, siret: siret_a, user: user_a) }

  let(:user_b) { create(:user) }
  let(:market_b) { create(:public_market, :completed, editor:, name: 'Marché candidat B') }
  let(:app_b) { create(:market_application, public_market: market_b, siret: siret_b, user: user_b) }

  let(:login_form_marker) { 'candidate/sessions' }

  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  def shows_login_form
    expect(response.body).to include(login_form_marker)
  end

  def grants_access
    expect(response).not_to have_http_status(:not_found)
    expect(response.body).not_to include(login_form_marker)
  end

  describe 'CompanyIdentificationsController' do
    let(:path) { company_identification_candidate_market_application_path(app_a.identifier) }

    context 'when unauthenticated' do
      it 'GET renders the login form' do
        get path
        shows_login_form
      end

      it 'PATCH renders the login form' do
        patch path
        shows_login_form
      end
    end

    context 'when authenticated for a different application (cross-app)' do
      before { sign_in_as_candidate(user_b, app_b) }

      it 'GET renders the login form' do
        get path
        shows_login_form
      end

      it 'PATCH renders the login form' do
        patch path
        shows_login_form
      end

      it 'clears the session' do
        get path
        expect(session[:user_id]).to be_nil
      end
    end

    context 'when authenticated for own application but different SIRET (cross-siret)' do
      let(:other_siret_market) { create(:public_market, :completed, editor:) }
      let(:other_siret_app) do
        create(:market_application, public_market: other_siret_market, siret: siret_b, user: user_a)
      end
      let(:cross_siret_path) { company_identification_candidate_market_application_path(other_siret_app.identifier) }

      before { sign_in_as_candidate(user_a, app_a) }

      it 'GET renders the login form' do
        get cross_siret_path
        shows_login_form
      end
    end

    context 'when authenticated for own application' do
      before { sign_in_as_candidate(user_a, app_a) }

      it 'GET grants access' do
        get path
        grants_access
      end
    end
  end

  describe 'MarketApplicationsController (wizard steps)' do
    let(:step_path) { step_candidate_market_application_path(app_a.identifier, :market_information) }

    context 'when unauthenticated' do
      it 'GET renders the login form' do
        get step_path
        shows_login_form
      end

      it 'PATCH renders the login form' do
        patch step_path
        shows_login_form
      end
    end

    context 'when authenticated for a different application (cross-app)' do
      before { sign_in_as_candidate(user_b, app_b) }

      it 'GET renders the login form' do
        get step_path
        shows_login_form
      end

      it 'PATCH renders the login form' do
        patch step_path
        shows_login_form
      end

      it 'clears the session' do
        get step_path
        expect(session[:user_id]).to be_nil
      end
    end

    context 'when authenticated for own application' do
      before { sign_in_as_candidate(user_a, app_a) }

      it 'GET grants access' do
        get step_path
        grants_access
      end
    end
  end

  describe 'SyncStatusController' do
    let(:completed_app_a) { create(:market_application, :completed, public_market: market_a, siret: siret_a, user: user_a) }
    let(:sync_path) { candidate_sync_status_path(completed_app_a.identifier) }

    context 'when unauthenticated' do
      it 'renders the login form' do
        get sync_path
        shows_login_form
      end
    end

    context 'when authenticated for a different application (cross-app)' do
      before { sign_in_as_candidate(user_b, app_b) }

      it 'renders the login form' do
        get sync_path
        shows_login_form
      end
    end

    context 'when authenticated for own application' do
      before { sign_in_as_candidate(user_a, completed_app_a) }

      it 'grants access' do
        get sync_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe 'AttachmentsController' do
    let(:signed_id) { 'fake-signed-id' }
    let(:attachment_path_a) { delete_attachment_candidate_market_application_path(app_a.identifier, signed_id) }
    let(:attachment_path_b) { delete_attachment_candidate_market_application_path(app_b.identifier, signed_id) }

    context 'when unauthenticated' do
      it 'does not execute the deletion' do
        delete attachment_path_a
        shows_login_form
      end
    end

    context 'when authenticated for a different application (cross-app)' do
      before { sign_in_as_candidate(user_a, app_a) }

      it 'does not allow deleting another application attachment' do
        delete attachment_path_b
        shows_login_form
      end
    end

    context 'when authenticated as a different user (cross-user)' do
      before { sign_in_as_candidate(user_b, app_b) }

      it 'does not allow deleting another user application attachment' do
        delete attachment_path_a
        shows_login_form
      end
    end
  end

  describe 'DashboardsController' do
    context 'when unauthenticated' do
      it 'renders the login form' do
        get candidate_dashboard_path
        shows_login_form
      end
    end

    context 'when authenticated' do
      before { sign_in_as_candidate(user_a, app_a) }

      it 'only shows applications for the authenticated SIRET, not other SIRETs of the same user' do
        other_siret_market = create(:public_market, :completed, editor:, name: 'Marché autre SIRET')
        other_siret_app = create(:market_application, public_market: other_siret_market,
          siret: siret_b, user: user_a)

        get candidate_dashboard_path

        expect(response.body).to include(app_a.public_market.name)
        expect(response.body).not_to include(other_siret_app.public_market.name)
      end

      it 'does not show other users applications even with the same SIRET' do
        intruder_market = create(:public_market, :completed, editor:, name: 'Marché intrus')
        create(:market_application, public_market: intruder_market,
          siret: siret_a, user: user_b)

        get candidate_dashboard_path

        expect(response.body).not_to include(intruder_market.name)
      end
    end
  end
end
