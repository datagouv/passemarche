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

      context 'when the application is a groupement the user is mandataire of' do
        let(:application) { create(:market_application, public_market:, user:, application_mode: :groupement) }

        before do
          allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
          create(:grouping, public_market:, mandataire_market_application: application)
        end

        it 'shows a link to the grouping dashboard instead of the edit link' do
          get candidate_dashboard_path

          expect(response.body).to include(
            grouping_dashboard_candidate_market_application_path(application.identifier)
          )
        end

        it 'does not show the delete button' do
          get candidate_dashboard_path

          expect(response.body).not_to include(I18n.t('candidate.dashboard.actions.delete'))
        end
      end

      context 'when the application is a groupement the user is co-traitant of' do
        let(:application) { create(:market_application, public_market:, user:, application_mode: :groupement) }

        before do
          allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
          mandataire_application = create(:market_application, public_market:, siret: '41816609600069',
            application_mode: :groupement)
          grouping = create(:grouping, public_market:, mandataire_market_application: mandataire_application)
          create(:grouping_member, :co_traitant, grouping:, market_application: application, siret: application.siret)
        end

        it 'shows the edit link' do
          get candidate_dashboard_path

          expect(response.body).to include(
            company_identification_candidate_market_application_path(application.identifier)
          )
        end

        it 'does not show the delete button' do
          get candidate_dashboard_path

          expect(response.body).not_to include(I18n.t('candidate.dashboard.actions.delete'))
        end
      end

      context 'when the groupement feature is disabled' do
        let(:application) { create(:market_application, public_market:, user:, application_mode: :groupement) }

        before do
          allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(false)
          create(:grouping, public_market:, mandataire_market_application: application)
          create(:market_application, public_market: create(:public_market, :completed, name: 'Marché individuel'),
            user:, siret: application.siret, application_mode: :solo)
        end

        it 'hides the grouping applications' do
          get candidate_dashboard_path

          expect(response.body).not_to include(public_market.name)
        end

        it 'keeps the individual applications' do
          get candidate_dashboard_path

          expect(response.body).to include('Marché individuel')
        end
      end

      context 'when ten markets hold eleven applications' do
        before do
          create(:market_application, public_market:, user:, siret: application.siret)
          9.times do
            create(:market_application, public_market: create(:public_market, :completed), user:,
              siret: application.siret)
          end
        end

        it 'paginates by market and shows every application of the page' do
          get candidate_dashboard_path

          expect(response.body.scan('dashboard-application-row ').size).to eq(11)
        end
      end
    end
  end
end
