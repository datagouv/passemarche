# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::GroupingDashboards', type: :request do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:siret) { '73282932000074' }
  let(:mandataire_application) { create(:market_application, public_market:, siret:, application_mode: :groupement) }
  let(:grouping) { create(:grouping, public_market:, mandataire_market_application: mandataire_application) }
  let(:user) { create(:user, email: 'mandataire@example.com') }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
    allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
    grouping
  end

  describe 'GET #show' do
    context 'when signed in as the mandataire' do
      before { sign_in_as_candidate(user, mandataire_application) }

      it 'returns ok' do
        get grouping_dashboard_candidate_market_application_path(mandataire_application.identifier)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the market_application is not linked to any grouping' do
      let(:solo_application) { create(:market_application, public_market:, siret: '80245139600021', application_mode: :solo) }

      before { sign_in_as_candidate(user, solo_application) }

      it 'redirects to the application mode choice step' do
        get grouping_dashboard_candidate_market_application_path(solo_application.identifier)

        expect(response).to redirect_to(
          grouping_wizard_step_candidate_market_application_path(solo_application.identifier, :application_mode)
        )
      end
    end

    context 'when signed in as a co_traitant of the grouping (not mandataire)' do
      let(:co_traitant_application) do
        create(:market_application, public_market:, siret: '80245139600021', application_mode: :groupement)
      end
      let!(:co_traitant_member) do
        create(:grouping_member, :co_traitant, grouping:, siret: co_traitant_application.siret,
          market_application: co_traitant_application)
      end
      let(:co_traitant_user) { create(:user, email: 'cotraitant@example.com') }

      before { sign_in_as_candidate(co_traitant_user, co_traitant_application) }

      it 'redirects to the application mode choice step' do
        get grouping_dashboard_candidate_market_application_path(co_traitant_application.identifier)

        expect(response).to redirect_to(
          grouping_wizard_step_candidate_market_application_path(co_traitant_application.identifier, :application_mode)
        )
      end
    end

    context 'when the groupement feature flag is disabled' do
      before do
        allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(false)
        sign_in_as_candidate(user, mandataire_application)
      end

      it 'returns not_found' do
        get grouping_dashboard_candidate_market_application_path(mandataire_application.identifier)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when not authenticated' do
      it 'renders the sign in form' do
        get grouping_dashboard_candidate_market_application_path(mandataire_application.identifier)

        expect(response.body).to include('candidate')
      end
    end

    context 'when rendering the full page with members in every status' do
      before do
        lot = create(:lot, public_market:, name: 'Lot A')
        mandataire_application.lots << lot
        grouping.mandataire_grouping_member.update!(status: :completed)

        create(:grouping_member, :co_traitant, grouping:, siret: '80245139600021', email: 'a@example.com',
          status: :invited)
        to_prepare_app = create(:market_application, public_market:, application_mode: :groupement)
        create(:grouping_member, :co_traitant, grouping:, siret: '80245139600022', email: 'b@example.com',
          status: :to_prepare, market_application: to_prepare_app)
        in_progress_app = create(:market_application, public_market:, application_mode: :groupement)
        create(:grouping_member, :co_traitant, grouping:, siret: '80245139600023', email: 'c@example.com',
          status: :in_progress, market_application: in_progress_app)

        solo_application = create(:market_application, public_market:, siret:, application_mode: :solo)
        sign_in_as_candidate(user, mandataire_application)
        solo_application.update!(user:)
      end

      it 'renders every section without error' do
        get grouping_dashboard_candidate_market_application_path(mandataire_application.identifier)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Lot A')
        expect(response.body).to include(I18n.t('candidate.grouping_dashboard.solo_application_title'))
        expect(response.body).to include(I18n.t('candidate.grouping_dashboard.status_invited'))
        expect(response.body).to include(I18n.t('candidate.grouping_dashboard.status_to_prepare'))
        expect(response.body).to include(I18n.t('candidate.grouping_dashboard.status_in_progress'))
      end
    end

    context 'when all members are completed' do
      before do
        grouping.mandataire_grouping_member.update!(status: :completed)
        completed_app = create(:market_application, public_market:, application_mode: :groupement)
        create(:grouping_member, :co_traitant, grouping:, status: :completed, market_application: completed_app)
        sign_in_as_candidate(user, mandataire_application)
      end

      it 'shows the ready-to-submit banner' do
        get grouping_dashboard_candidate_market_application_path(mandataire_application.identifier)

        expect(response.body).to include(I18n.t('candidate.grouping_dashboard.submission_ready_title'))
      end
    end

    context 'when a co_traitant has not joined yet (no market_application)' do
      before do
        create(:grouping_member, :co_traitant, grouping:, market_application: nil)
        sign_in_as_candidate(user, mandataire_application)
      end

      it 'shows "not provided" for their declared lots' do
        get grouping_dashboard_candidate_market_application_path(mandataire_application.identifier)

        expect(response.body).to include(I18n.t('candidate.grouping_dashboard.declared_lots_not_provided'))
      end
    end
  end

  describe 'POST #regenerate_invitation_link' do
    let(:co_traitant_member) { create(:grouping_member, :co_traitant, grouping:) }

    before { sign_in_as_candidate(user, mandataire_application) }

    it 'regenerates the invitation token' do
      co_traitant_member.update!(invitation_token: 'old-token', invitation_token_created_at: 1.day.ago)

      expect do
        post regenerate_grouping_dashboard_invitation_link_candidate_market_application_path(
          mandataire_application.identifier, co_traitant_member
        )
      end.to change { co_traitant_member.reload.invitation_token }.from('old-token')
    end

    it 'returns ok' do
      post regenerate_grouping_dashboard_invitation_link_candidate_market_application_path(
        mandataire_application.identifier, co_traitant_member
      )

      expect(response).to have_http_status(:ok)
    end
  end
end
