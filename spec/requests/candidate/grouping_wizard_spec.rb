# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Candidate::GroupingWizard', type: :request do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }
  let(:user) { create(:user) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
    allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)
    sign_in_as_candidate(user, market_application)
  end

  def wizard_step_path(market_application, step)
    grouping_wizard_step_candidate_market_application_path(market_application.identifier, step)
  end

  describe 'authentication' do
    it 'renders the login form instead of the page when not authenticated' do
      other_application = create(:market_application, public_market:, siret: '11122233300014')

      get wizard_step_path(other_application, :application_mode)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t('candidate.sessions.new.title'))
      expect(response.body).not_to include(I18n.t('candidate.application_modes.title'))
    end
  end

  describe 'GET .../grouping_wizard/application_mode' do
    it 'renders successfully when the mode is not chosen yet' do
      get wizard_step_path(market_application, :application_mode)
      expect(response).to have_http_status(:ok)
    end

    it 'returns 404 when the feature flag is disabled' do
      allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(false)

      get wizard_step_path(market_application, :application_mode)
      expect(response).to have_http_status(:not_found)
    end

    it 'redirects to company_identification when the mode is already chosen and readonly is not requested' do
      market_application.update!(application_mode: :solo)

      get wizard_step_path(market_application, :application_mode)
      expect(response).to redirect_to(
        company_identification_candidate_market_application_path(market_application.identifier)
      )
    end

    context 'when the application is already completed' do
      let(:market_application) do
        create(:market_application, :completed, public_market:, siret: '73282932000074')
      end

      it 'redirects to sync status instead of showing the choice screen' do
        get wizard_step_path(market_application, :application_mode)

        expect(response).to redirect_to(candidate_sync_status_path(market_application.identifier))
      end
    end
  end

  describe 'PATCH .../grouping_wizard/application_mode' do
    it 'sets the mode to solo and redirects to company_identification' do
      patch wizard_step_path(market_application, :application_mode), params: { application_mode: 'solo' }

      expect(market_application.reload).to be_solo
      expect(response).to redirect_to(
        company_identification_candidate_market_application_path(market_application.identifier)
      )
    end

    it 'creates a grouping when choosing groupement and redirects to grouping_legal_type' do
      expect do
        patch wizard_step_path(market_application, :application_mode), params: { application_mode: 'groupement' }
      end.to change(Grouping, :count).by(1)

      expect(market_application.reload).to be_groupement
      expect(response).to redirect_to(wizard_step_path(market_application, :grouping_legal_type))
    end

    it 'creates two applications when choosing mixte and redirects to grouping_legal_type of the groupement counterpart' do
      expect do
        patch wizard_step_path(market_application, :application_mode), params: { application_mode: 'mixte' }
      end.to change(MarketApplication, :count).by(1)

      groupement_application = MarketApplication.find_by(public_market:, siret: market_application.siret,
        application_mode: :groupement)
      expect(response).to redirect_to(wizard_step_path(groupement_application, :grouping_legal_type))
    end

    it 'does not require re-authentication when reaching the next step after choosing groupement' do
      patch wizard_step_path(market_application, :application_mode), params: { application_mode: 'groupement' }

      get wizard_step_path(market_application, :grouping_legal_type)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(I18n.t('candidate.sessions.new.siret_label'))
    end

    it 'associates the authenticated user to the groupement counterpart created in mixte mode' do
      patch wizard_step_path(market_application, :application_mode), params: { application_mode: 'mixte' }

      groupement_application = MarketApplication.where(public_market:, siret: market_application.siret,
        application_mode: :groupement).sole

      expect(groupement_application.user).to eq(user)
    end

    it 'does not require re-authentication when reaching the next step after choosing mixte' do
      patch wizard_step_path(market_application, :application_mode), params: { application_mode: 'mixte' }

      groupement_application = MarketApplication.where(public_market:, siret: market_application.siret,
        application_mode: :groupement).sole

      get wizard_step_path(groupement_application, :grouping_legal_type)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(I18n.t('candidate.sessions.new.siret_label'))
    end

    context 'when the SIRET is already mandataire of a grouping on this market' do
      before do
        other_application = create(:market_application, public_market:, siret: market_application.siret,
          application_mode: :groupement)
        create(:grouping, public_market:, mandataire_market_application: other_application)
      end

      it 'rejects groupement mode with a 422' do
        patch wizard_step_path(market_application, :application_mode), params: { application_mode: 'groupement' }

        expect(response).to have_http_status(:unprocessable_content)
        expect(market_application.reload.application_mode).to be_nil
      end

      it 'renders the already-mandataire error message and re-disables groupement/mixte' do
        patch wizard_step_path(market_application, :application_mode), params: { application_mode: 'groupement' }

        rendered = Nokogiri::HTML(response.body)
        expect(rendered.text).to include(I18n.t('candidate.validations.already_mandataire'))
        expect(rendered.text).to include(I18n.t('candidate.application_modes.already_mandataire_box.title'))

        expect(rendered.at_css('#application_mode_groupement')['disabled']).to eq('disabled')
        expect(rendered.at_css('#application_mode_mixte')['disabled']).to eq('disabled')
      end

      it 'still allows solo mode' do
        patch wizard_step_path(market_application, :application_mode), params: { application_mode: 'solo' }

        expect(response).to redirect_to(
          company_identification_candidate_market_application_path(market_application.identifier)
        )
      end
    end

    context 'when the mode is already chosen' do
      before do
        market_application.update!(application_mode: :groupement)
        create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint)
      end

      it 'ignores the resubmitted mode and redirects to the current step, without changing application_mode' do
        expect do
          patch wizard_step_path(market_application, :application_mode), params: { application_mode: 'solo' }
        end.not_to change { market_application.reload.application_mode }

        expect(response).to redirect_to(wizard_step_path(market_application, :grouping_legal_type))
      end

      it 'does not orphan the existing grouping' do
        expect do
          patch wizard_step_path(market_application, :application_mode), params: { application_mode: 'solo' }
        end.not_to change(Grouping, :count)
      end
    end
  end

  describe 'readonly navigation (application_mode already chosen)' do
    context 'when the mode is groupement and no co-traitant has been added yet' do
      before do
        market_application.update!(application_mode: :groupement)
        create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint)
      end

      it 'renders the screen in readonly instead of redirecting' do
        get wizard_step_path(market_application, :application_mode), params: { readonly: true }

        expect(response).to have_http_status(:ok)
      end

      it 'disables the fieldset' do
        get wizard_step_path(market_application, :application_mode), params: { readonly: true }

        rendered = Nokogiri::HTML(response.body)
        expect(rendered.at_css('fieldset')['disabled']).to eq('disabled')
      end

      it 'checks the already chosen mode' do
        get wizard_step_path(market_application, :application_mode), params: { readonly: true }

        rendered = Nokogiri::HTML(response.body)
        expect(rendered.at_css('#application_mode_groupement')['checked']).to eq('checked')
      end

      it 'does not show the already-mandataire-elsewhere callout for its own grouping' do
        get wizard_step_path(market_application, :application_mode), params: { readonly: true }

        rendered = Nokogiri::HTML(response.body)
        expect(rendered.text).not_to include(I18n.t('candidate.application_modes.already_mandataire_box.title'))
      end

      it 'points the continue link to grouping_legal_type, not skipping it' do
        get wizard_step_path(market_application, :application_mode), params: { readonly: true }

        rendered = Nokogiri::HTML(response.body)
        link = rendered.at_css('a.fr-icon-arrow-right-line')
        expect(link['href']).to eq(wizard_step_path(market_application, :grouping_legal_type))
      end
    end

    context 'regression: revisiting application_mode after the legal type is already chosen must not skip it' do
      before do
        market_application.update!(application_mode: :groupement)
        create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint)
      end

      it 'still points the continue link to grouping_legal_type (never jumps straight to grouping_composition)' do
        get wizard_step_path(market_application, :application_mode), params: { readonly: true }

        rendered = Nokogiri::HTML(response.body)
        link = rendered.at_css('a.fr-icon-arrow-right-line')
        expect(link['href']).to eq(wizard_step_path(market_application, :grouping_legal_type))
      end

      it 'allows navigating back to grouping_legal_type and seeing the previously chosen type' do
        get wizard_step_path(market_application, :grouping_legal_type)

        rendered = Nokogiri::HTML(response.body)
        expect(rendered.at_css('#legal_type_conjoint')['checked']).to eq('checked')
      end
    end

    context 'when the mode is not groupement/mixte (solo)' do
      before { market_application.update!(application_mode: :solo) }

      it 'points the continue link to company_identification' do
        get wizard_step_path(market_application, :application_mode), params: { readonly: true }

        rendered = Nokogiri::HTML(response.body)
        link = rendered.at_css('a.fr-icon-arrow-right-line')
        expect(link['href']).to eq(company_identification_candidate_market_application_path(market_application.identifier))
      end
    end

    context 'for the solo side of a mixte application with an incomplete groupement counterpart' do
      let!(:groupement_application) do
        create(:market_application, public_market:, siret: market_application.siret, application_mode: :groupement, user:)
      end

      before do
        market_application.update!(application_mode: :solo)
        create(:grouping, public_market:, mandataire_market_application: groupement_application, legal_type: nil)
      end

      it 'points the continue link to the groupement counterpart grouping_legal_type step' do
        get wizard_step_path(market_application, :application_mode), params: { readonly: true }

        rendered = Nokogiri::HTML(response.body)
        link = rendered.at_css('a.fr-icon-arrow-right-line')
        expect(link['href']).to eq(wizard_step_path(groupement_application, :grouping_legal_type))
      end
    end

    context 'for the solo side of a mixte application with a completed groupement counterpart' do
      let!(:groupement_application) do
        create(:market_application, public_market:, siret: market_application.siret, application_mode: :groupement, user:)
      end

      before do
        market_application.update!(application_mode: :solo)
        grouping = create(:grouping, public_market:, mandataire_market_application: groupement_application, legal_type: :conjoint)
        create(:grouping_member, :co_traitant, grouping:, invitation_token_created_at: Time.current)
      end

      it 'points the continue link to its own company_identification step' do
        get wizard_step_path(market_application, :application_mode), params: { readonly: true }

        rendered = Nokogiri::HTML(response.body)
        link = rendered.at_css('a.fr-icon-arrow-right-line')
        expect(link['href']).to eq(company_identification_candidate_market_application_path(market_application.identifier))
      end
    end
  end

  describe 'GET .../grouping_wizard/grouping_legal_type' do
    context 'when the market_application is mandataire of a grouping' do
      before do
        market_application.update!(application_mode: :groupement)
        create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: nil)
      end

      it 'renders successfully' do
        get wizard_step_path(market_application, :grouping_legal_type)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(I18n.t('candidate.grouping_legal_types.title'))
      end
    end

    context 'when the market_application is not mandataire of any grouping (mode not chosen)' do
      it 'redirects to application_mode' do
        get wizard_step_path(market_application, :grouping_legal_type)

        expect(response).to redirect_to(wizard_step_path(market_application, :application_mode))
      end
    end

    context 'when the application mode is solo' do
      before { market_application.update!(application_mode: :solo) }

      it 'redirects to application_mode' do
        get wizard_step_path(market_application, :grouping_legal_type)

        expect(response).to redirect_to(wizard_step_path(market_application, :application_mode))
      end
    end
  end

  describe 'PATCH .../grouping_wizard/grouping_legal_type' do
    before do
      market_application.update!(application_mode: :groupement)
      create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: nil)
    end

    it 'sets the legal_type and redirects to grouping_composition' do
      patch wizard_step_path(market_application, :grouping_legal_type), params: { legal_type: 'conjoint_mandataire_solidaire' }

      grouping = Grouping.joins(:mandataire_grouping_member)
        .find_by(mandataire_grouping_member: { market_application_id: market_application.id })
      expect(grouping.legal_type).to eq('conjoint_mandataire_solidaire')
      expect(response).to redirect_to(wizard_step_path(market_application, :grouping_composition))
    end

    it 'rejects an invalid legal_type with a 422' do
      patch wizard_step_path(market_application, :grouping_legal_type), params: { legal_type: 'invalid_garbage' }

      expect(response).to have_http_status(:unprocessable_content)
      rendered = Nokogiri::HTML(response.body)
      expect(rendered.text).to include(I18n.t('candidate.validations.legal_type_invalid'))
    end
  end

  describe 'GET .../grouping_wizard/grouping_composition' do
    context 'when the market_application is mandataire of a grouping with a legal_type' do
      before do
        market_application.update!(application_mode: :groupement)
        create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint)
        allow(FetchRaisonSociale).to receive(:call).and_return(OpenStruct.new(success?: true, raison_sociale: 'ATLANTIQUE BÂTIMENT SAS'))
      end

      it 'renders successfully' do
        get wizard_step_path(market_application, :grouping_composition)

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
        get wizard_step_path(market_application, :grouping_composition)

        expect(mandataire_member.reload.company_name).to eq('ATLANTIQUE BÂTIMENT SAS')
      end

      it 'displays the resolved company name' do
        get wizard_step_path(market_application, :grouping_composition)

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

        get wizard_step_path(market_application, :grouping_composition)

        expect(FetchRaisonSociale).not_to have_received(:call)
      end
    end

    context 'when the market_application is not mandataire of any grouping' do
      it 'redirects to application_mode' do
        get wizard_step_path(market_application, :grouping_composition)

        expect(response).to redirect_to(wizard_step_path(market_application, :application_mode))
      end
    end
  end

  describe 'POST .../grouping_wizard/members' do
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
      post grouping_wizard_members_candidate_market_application_path(market_application.identifier),
        params: { siret: '80245139600027', email: 'contact@menuiseries-loire.fr' },
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/vnd.turbo-stream.html')
      expect(grouping.grouping_members.co_traitant.count).to eq(1)
    end

    it 'renders errors inline without creating a member when the siret is invalid' do
      allow(SiretValidator).to receive(:valid?).with('0000000000').and_return(false)

      post grouping_wizard_members_candidate_market_application_path(market_application.identifier),
        params: { siret: '0000000000', email: 'contact@menuiseries-loire.fr' },
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:unprocessable_content)
      expect(grouping.grouping_members.co_traitant.count).to eq(0)
      expect(response.body).to include(I18n.t('candidate.validations.siret_invalid'))
    end
  end

  describe 'DELETE .../grouping_wizard/members/:id' do
    before { market_application.update!(application_mode: :groupement) }

    let!(:grouping) do
      create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint)
    end
    let!(:member) { create(:grouping_member, :co_traitant, grouping:, invitation_token_created_at: nil) }

    it 'removes the member and returns a turbo stream response' do
      delete grouping_wizard_member_candidate_market_application_path(market_application.identifier, member.id),
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:ok)
      expect(GroupingMember.exists?(member.id)).to be false
    end
  end

  describe 'GET .../grouping_wizard/grouping_composition_confirmation' do
    before { market_application.update!(application_mode: :groupement) }

    let!(:grouping) do
      create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint)
    end

    it 'renders the summary' do
      create(:grouping_member, :co_traitant, grouping:)

      get wizard_step_path(market_application, :grouping_composition_confirmation)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t('candidate.grouping_compositions.confirm.title'))
    end

    it 'redirects back to grouping_composition when there is no co-traitant yet' do
      get wizard_step_path(market_application, :grouping_composition_confirmation)

      expect(response).to redirect_to(wizard_step_path(market_application, :grouping_composition))
    end
  end

  describe 'PATCH .../grouping_wizard/grouping_composition_confirmation' do
    before { market_application.update!(application_mode: :groupement) }

    let!(:grouping) do
      create(:grouping, public_market:, mandataire_market_application: market_application, legal_type: :conjoint)
    end

    context 'when the grouping has at least one co_traitant' do
      before { create(:grouping_member, :co_traitant, grouping:, invitation_token_created_at: nil) }

      it 'sends invitations and redirects to the dashboard with a success message' do
        patch wizard_step_path(market_application, :grouping_composition_confirmation)

        expect(response).to redirect_to(candidate_dashboard_path)
        follow_redirect!
        expect(response.body).to include(I18n.t('candidate.grouping_compositions.success'))
      end
    end

    context 'when the confirmation interactor fails' do
      before { create(:grouping_member, :co_traitant, grouping:, invitation_token_created_at: nil) }

      it 'renders the summary with an error' do
        allow(Candidate::ConfirmGroupingComposition).to receive(:call).and_return(
          OpenStruct.new(success?: false, errors: { grouping: [I18n.t('candidate.validations.no_co_traitant')] })
        )

        patch wizard_step_path(market_application, :grouping_composition_confirmation)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t('candidate.validations.no_co_traitant'))
      end
    end
  end
end
