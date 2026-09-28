# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::GroupingSubmissions', type: :request do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }
  let(:user) { create(:user) }

  let!(:grouping) do
    create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint)
  end

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
    allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
    sign_in_as_candidate(user, market_application)
    market_application.update!(application_mode: :groupement)
    create(:grouping_member, :co_traitant, grouping:, invitation_token_created_at: Time.current)
  end

  describe 'POST .../grouping_submission' do
    context 'when submission_mode is full and every member is completed' do
      before do
        grouping.mandataire_grouping_member.update!(status: :completed)
        grouping.grouping_members.co_traitant.first.update!(status: :completed)
      end

      it 'submits the grouping and redirects to the confirmation screen' do
        post grouping_submission_candidate_market_application_path(market_application.identifier), params: { submission_mode: 'full' }

        expect(grouping.reload).to be_submitted
        expect(response).to redirect_to(grouping_submission_candidate_market_application_path(market_application.identifier))
      end
    end

    context 'when the mandataire own market_application is already completed' do
      before do
        market_application.complete!
        grouping.mandataire_grouping_member.update!(status: :completed)
        grouping.grouping_members.co_traitant.first.update!(status: :completed)
      end

      it 'still allows the mandataire to submit the grouping' do
        post grouping_submission_candidate_market_application_path(market_application.identifier), params: { submission_mode: 'full' }

        expect(grouping.reload).to be_submitted
        expect(response).to redirect_to(grouping_submission_candidate_market_application_path(market_application.identifier))
      end
    end

    context 'when submission_mode is partial and at least one member has started' do
      before { grouping.grouping_members.co_traitant.first.update!(status: :in_progress) }

      it 'submits the grouping and redirects to the confirmation screen' do
        post grouping_submission_candidate_market_application_path(market_application.identifier), params: { submission_mode: 'partial' }

        expect(grouping.reload).to be_submitted
        expect(response).to redirect_to(grouping_submission_candidate_market_application_path(market_application.identifier))
      end
    end

    context 'when the submission is not allowed' do
      it 'redirects back to the dashboard with an alert' do
        post grouping_submission_candidate_market_application_path(market_application.identifier), params: { submission_mode: 'full' }

        expect(grouping.reload).not_to be_submitted
        expect(response).to redirect_to(grouping_dashboard_candidate_market_application_path(market_application.identifier))
        expect(flash[:alert]).to be_present
      end
    end

    context 'when submission_mode is missing' do
      before do
        grouping.mandataire_grouping_member.update!(status: :completed)
        grouping.grouping_members.co_traitant.first.update!(status: :completed)
      end

      it 'redirects back to the dashboard with an alert instead of raising' do
        expect do
          post grouping_submission_candidate_market_application_path(market_application.identifier)
        end.not_to raise_error

        expect(grouping.reload).not_to be_submitted
        expect(response).to redirect_to(grouping_dashboard_candidate_market_application_path(market_application.identifier))
        expect(flash[:alert]).to eq('Mode de soumission invalide')
      end
    end

    context 'when the current user is not the mandataire' do
      let(:co_traitant_application) { create(:market_application, public_market:, siret: '39822709000032') }

      before do
        allow(SiretValidator).to receive(:valid?).with(co_traitant_application.siret).and_return(true)
        sign_in_as_candidate(user, co_traitant_application)
      end

      it 'redirects away' do
        post grouping_submission_candidate_market_application_path(co_traitant_application.identifier), params: { submission_mode: 'full' }

        expect(response).to redirect_to(application_mode_candidate_market_application_path(co_traitant_application.identifier))
      end
    end

    context 'when the groupement feature flag is disabled' do
      before { allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(false) }

      it 'returns not_found' do
        post grouping_submission_candidate_market_application_path(market_application.identifier), params: { submission_mode: 'full' }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET .../grouping_submission' do
    context 'when the grouping is submitted' do
      before { grouping.update!(submitted_at: Time.current, submission_mode: :full) }

      it 'renders the confirmation screen' do
        get grouping_submission_candidate_market_application_path(market_application.identifier)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the grouping is not submitted yet' do
      it 'redirects to the dashboard' do
        get grouping_submission_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(grouping_dashboard_candidate_market_application_path(market_application.identifier))
      end
    end

    context 'when the groupement feature flag is disabled' do
      before do
        grouping.update!(submitted_at: Time.current, submission_mode: :full)
        allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(false)
      end

      it 'returns not_found' do
        get grouping_submission_candidate_market_application_path(market_application.identifier)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
