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

      before do
        allow(FetchRaisonSociale).to receive(:call).and_return(
          OpenStruct.new(success?: true, raison_sociale: 'ATLANTIQUE BÂTIMENT SAS')
        )
      end

      it 'resolves and persists the company name' do
        get grouping_composition_candidate_market_application_path(market_application.identifier)

        expect(mandataire_member.reload.company_name).to eq('ATLANTIQUE BÂTIMENT SAS')
      end

      it 'displays the resolved company name' do
        get grouping_composition_candidate_market_application_path(market_application.identifier)

        expect(response.body).to include('ATLANTIQUE BÂTIMENT SAS')
      end
    end

    context 'when the mandataire member already has a company_name' do
      before { market_application.update!(application_mode: :groupement) }

      let!(:grouping) { create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint) }
      let!(:mandataire_member) do
        grouping.mandataire_grouping_member.tap { |m| m.update!(company_name: 'ATLANTIQUE BÂTIMENT SAS') }
      end

      it 'does not call the API again' do
        allow(FetchRaisonSociale).to receive(:call)

        get grouping_composition_candidate_market_application_path(market_application.identifier)

        expect(FetchRaisonSociale).not_to have_received(:call)
      end
    end

    context 'when the market_application is not mandataire of any grouping' do
      it 'redirects to application_mode' do
        get grouping_composition_candidate_market_application_path(market_application.identifier)

        expect(response).to redirect_to(application_mode_candidate_market_application_path(market_application.identifier))
      end
    end
  end

  describe 'POST .../grouping_composition/members' do
    before { market_application.update!(application_mode: :groupement) }

    let!(:grouping) do
      create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint)
    end

    before do
      allow(FetchRaisonSociale).to receive(:call).and_return(
        OpenStruct.new(success?: true, raison_sociale: 'MENUISERIES DE LOIRE SARL')
      )
    end

    it 'creates a co_traitant member and returns a turbo stream response' do
      post grouping_composition_members_candidate_market_application_path(market_application.identifier),
        params: { siret: '80245139600027', email: 'contact@menuiseries-loire.fr' },
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(grouping.grouping_members.co_traitant.count).to eq(1)
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
