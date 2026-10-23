# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::LockedApplications', type: :request do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:mandataire_application) do
    create(:market_application, public_market:, siret: '80245139600099', application_mode: :groupement)
  end
  let(:grouping) { create(:grouping, public_market:, mandataire_market_application: mandataire_application) }
  let(:co_traitant_application) do
    create(:market_application, :completed, public_market:, siret: '80245139600021', application_mode: :groupement)
  end

  before do
    allow_any_instance_of(Candidate::ApplicationController).to receive(:current_candidate).and_return(create(:user))
    allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
    allow(SiretValidator).to receive(:valid?).and_return(true)
    create(:grouping_member, :co_traitant, grouping:, siret: co_traitant_application.siret,
      market_application: co_traitant_application, status: :completed)
  end

  describe 'GET #show' do
    context 'when the mandataire has submitted the grouping' do
      before { grouping.update!(submitted_at: Time.current, submission_mode: :full) }

      it 'explains that only the mandataire can allow a modification' do
        get locked_candidate_market_application_path(co_traitant_application.identifier)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t('candidate.locked_applications.heading'))
        expect(response.body).to include(I18n.t('candidate.locked_applications.explanation'))
      end

      it 'does not offer to download any attestation' do
        get locked_candidate_market_application_path(co_traitant_application.identifier)

        expect(response.body).not_to include('ttestation')
      end

      it 'does not show the co_traitant lock screen to the mandataire' do
        get locked_candidate_market_application_path(mandataire_application.identifier)

        expect(response).to redirect_to(
          step_candidate_market_application_path(mandataire_application.identifier, :market_information)
        )
      end
    end

    context 'when the candidate is not authenticated' do
      before do
        grouping.update!(submitted_at: Time.current, submission_mode: :full)
        allow_any_instance_of(Candidate::ApplicationController).to receive(:current_candidate).and_return(nil)
      end

      it 'asks the candidate to sign in instead of showing the lock screen' do
        get locked_candidate_market_application_path(co_traitant_application.identifier)

        expect(response.body).not_to include(I18n.t('candidate.locked_applications.heading'))
      end
    end

    context 'when the groupement feature flag is disabled' do
      before do
        grouping.update!(submitted_at: Time.current, submission_mode: :full)
        allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(false)
      end

      it 'returns a 404' do
        get locked_candidate_market_application_path(co_traitant_application.identifier)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the grouping has not been submitted yet' do
      it 'sends the co_traitant back to its form' do
        get locked_candidate_market_application_path(co_traitant_application.identifier)

        expect(response).to redirect_to(
          step_candidate_market_application_path(co_traitant_application.identifier, :market_information)
        )
      end
    end
  end
end
