# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::GroupingCompositions', type: :request do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }
  let(:user) { create(:user) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
    allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
    sign_in_as_candidate(user, market_application)
  end

  describe 'GET .../grouping_composition' do
    context 'when the market_application is mandataire of a grouping with a legal_type' do
      before do
        market_application.update!(application_mode: :groupement)
        create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint)
        allow(FetchRaisonSociale).to receive(:call).and_return(OpenStruct.new(success?: true, raison_sociale: 'ATLANTIQUE BÂTIMENT SAS'))
      end

      it 'renders successfully' do
        get grouping_composition_candidate_market_application_path(market_application.identifier)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t('candidate.grouping_compositions.title'))
      end
    end

    context 'when the mandataire member has no company_name yet' do
      before { market_application.update!(application_mode: :groupement) }

      let!(:grouping) { create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint) }
      let!(:mandataire_member) { grouping.mandataire_grouping_member.tap { |m| m.update!(company_name: nil) } }

      it 'does not resolve the company name synchronously' do
        get grouping_composition_candidate_market_application_path(market_application.identifier)

        expect(response).to have_http_status(:ok)
        expect(mandataire_member.reload.company_name).to be_nil
      end

      it 'enqueues a job to resolve the company name' do
        expect { get grouping_composition_candidate_market_application_path(market_application.identifier) }
          .to have_enqueued_job(ResolveGroupingMemberCompanyNameJob).with(mandataire_member.id)
      end
    end

    context 'when the mandataire member already has a company_name' do
      before { market_application.update!(application_mode: :groupement) }

      let!(:grouping) { create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint) }
      let!(:mandataire_member) do
        grouping.mandataire_grouping_member.tap { |m| m.update!(company_name: 'ATLANTIQUE BÂTIMENT SAS') }
      end

      it 'displays the stored company name' do
        get grouping_composition_candidate_market_application_path(market_application.identifier)

        expect(response.body).to include('ATLANTIQUE BÂTIMENT SAS')
      end

      it 'does not enqueue a resolution job' do
        expect { get grouping_composition_candidate_market_application_path(market_application.identifier) }
          .not_to have_enqueued_job(ResolveGroupingMemberCompanyNameJob)
      end
    end

    context 'when requesting the json format' do
      before { market_application.update!(application_mode: :groupement) }

      let!(:grouping) { create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint) }

      it 'reports company_names_pending true while the mandataire company_name is unresolved' do
        grouping.mandataire_grouping_member.update!(company_name: nil)

        get grouping_composition_candidate_market_application_path(market_application.identifier, format: :json)

        expect(response.parsed_body).to eq('company_names_pending' => true)
      end

      it 'reports company_names_pending false once all company_names are resolved' do
        grouping.mandataire_grouping_member.update!(company_name: 'ATLANTIQUE BÂTIMENT SAS')

        get grouping_composition_candidate_market_application_path(market_application.identifier, format: :json)

        expect(response.parsed_body).to eq('company_names_pending' => false)
      end
    end

    context 'when the market_application is not mandataire of any grouping' do
      it 'redirects to application_mode' do
        get grouping_composition_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(application_mode_candidate_market_application_path(market_application.identifier))
      end
    end

    context 'when the grouping has no legal_type yet' do
      before do
        market_application.update!(application_mode: :groupement)
        create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: nil)
      end

      it 'redirects to grouping_legal_type instead of rendering the composition step' do
        get grouping_composition_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(grouping_legal_type_candidate_market_application_path(market_application.identifier))
      end
    end
  end

  describe 'POST .../grouping_composition/members' do
    before { market_application.update!(application_mode: :groupement) }

    let!(:grouping) do
      create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint)
    end

    it 'creates a co_traitant member and returns a turbo stream response' do
      post grouping_composition_members_candidate_market_application_path(market_application.identifier),
        params: { siret: '80245139600027', email: 'contact@menuiseries-loire.fr' },
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(grouping.grouping_members.co_traitant.count).to eq(1)
    end

    it 'enqueues a job to resolve the new member company name' do
      expect do
        post grouping_composition_members_candidate_market_application_path(market_application.identifier),
          params: { siret: '80245139600027', email: 'contact@menuiseries-loire.fr' },
          headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      end.to have_enqueued_job(ResolveGroupingMemberCompanyNameJob)
    end

    it 'renders errors inline without creating a member when the siret is invalid' do
      allow(SiretValidator).to receive(:valid?).with('0000000000').and_return(false)

      post grouping_composition_members_candidate_market_application_path(market_application.identifier),
        params: { siret: '0000000000', email: 'contact@menuiseries-loire.fr' },
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:unprocessable_content)
      expect(grouping.grouping_members.co_traitant.count).to eq(0)
      expect(response.body).to include(I18n.t('candidate.validations.siret_invalid'))
    end
  end

  describe 'DELETE .../grouping_composition/members/:id' do
    before { market_application.update!(application_mode: :groupement) }

    let!(:grouping) do
      create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint)
    end
    let!(:member) { create(:grouping_member, :co_traitant, grouping:, invitation_token_created_at: nil) }

    it 'removes the member and returns a turbo stream response' do
      delete grouping_composition_member_candidate_market_application_path(market_application.identifier, member.id),
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:ok)
      expect(GroupingMember.exists?(member.id)).to be false
    end
  end
end
