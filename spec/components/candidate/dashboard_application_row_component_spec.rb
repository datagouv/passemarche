# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::DashboardApplicationRowComponent, type: :component do
  let(:public_market) { create(:public_market, :completed) }
  let(:application) { Candidate::DashboardApplicationPresenter.new(market_application, public_market:) }

  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  context 'when the application is individual and in progress' do
    let(:market_application) { create(:market_application, public_market:, application_mode: :solo) }

    before { render_inline(described_class.new(application:)) }

    it 'renders its kind and status' do
      expect(page).to have_css('h3', text: 'Candidature individuelle')
      expect(page).to have_css('.fr-badge--info', text: 'En cours')
    end

    it 'renders the delete button with its confirmation modal' do
      expect(page).to have_button('Supprimer')
      expect(page).to have_css("dialog#deletion-modal-#{market_application.identifier}")
    end

    it 'renders the edit link' do
      expect(page).to have_link('Modifier')
    end
  end

  context 'when the application is the mandataire of a grouping' do
    let(:market_application) { create(:market_application, public_market:, application_mode: :groupement) }

    before do
      create(:grouping, public_market:, mandataire_market_application: market_application)
      render_inline(described_class.new(application:))
    end

    it 'renders the grouping follow-up link only' do
      expect(page).to have_link('Suivre le groupement')
      expect(page).to have_no_button('Supprimer')
    end
  end

  context 'when the application is a co-traitant whose part is sent to the mandataire' do
    let(:market_application) do
      create(:market_application, public_market:, application_mode: :groupement, completed_at: Time.zone.now)
    end

    before do
      mandataire_application = create(:market_application, public_market:, siret: '41816609600069',
        application_mode: :groupement)
      grouping = create(:grouping, public_market:, mandataire_market_application: mandataire_application)
      create(:grouping_member, :co_traitant, grouping:, market_application:, siret: market_application.siret)
      render_inline(described_class.new(application:))
    end

    it 'renders the mandataire and the sent status' do
      expect(page).to have_text('Mandataire : 41816609600069')
      expect(page).to have_css('.fr-badge--success', text: 'Transmise au mandataire')
    end

    it 'renders the view link only' do
      expect(page).to have_link('Consulter')
      expect(page).to have_no_link('Modifier')
    end
  end
end
