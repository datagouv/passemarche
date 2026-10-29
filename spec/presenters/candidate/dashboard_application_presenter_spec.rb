# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::DashboardApplicationPresenter do
  subject(:presenter) { described_class.new(market_application, public_market:) }

  let(:public_market) { create(:public_market, :completed) }

  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  context 'when the application is individual' do
    let(:market_application) { create(:market_application, public_market:, application_mode: :solo) }

    it 'is an individual application' do
      expect(presenter.kind).to eq(:individual)
    end

    it 'labels it as an individual application' do
      expect(presenter.kind_label).to eq('Candidature individuelle')
    end

    it 'uses the user icon' do
      expect(presenter.kind_icon_class).to eq('fr-icon-user-fill')
    end

    it 'shows its kind when the groupement feature is enabled' do
      allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(true)

      expect(presenter).to be_show_kind
    end

    it 'hides its kind when the groupement feature is disabled' do
      allow(FeatureFlags::Groupement).to receive(:enabled?).and_return(false)

      expect(presenter).not_to be_show_kind
    end

    it 'does not name any mandataire' do
      expect(presenter.mandataire_label).to be_nil
    end

    it 'is in progress' do
      expect(presenter.status).to eq(:in_progress)
    end

    it 'can be deleted or edited' do
      expect(presenter.actions).to eq(%i[delete edit])
    end

    context 'when it is completed' do
      before { market_application.update!(completed_at: Time.zone.local(2026, 10, 20, 10)) }

      it 'is submitted to the platform' do
        expect(presenter.status_label).to eq('Transmise à la plateforme')
      end

      it 'is dated on its completion' do
        expect(presenter.dated_on_label).to eq('Déposée le 20 octobre 2026')
      end

      it 'can only be viewed' do
        expect(presenter.actions).to eq(%i[view])
      end
    end

    context 'when the deadline has passed before completion' do
      before { public_market.update_column(:deadline, 1.day.ago) }

      it 'shows the deadline as passed' do
        expect(presenter.status_label).to eq('Date limite dépassée')
      end

      it 'can only be deleted' do
        expect(presenter.actions).to eq(%i[delete])
      end
    end
  end

  context 'when the application mode is not chosen yet' do
    let(:market_application) { create(:market_application, public_market:, application_mode: nil) }

    it 'is an individual application' do
      expect(presenter.kind).to eq(:individual)
    end
  end

  context 'when the application is the mandataire of a grouping' do
    let(:market_application) { create(:market_application, public_market:, application_mode: :groupement) }
    let!(:grouping) { create(:grouping, public_market:, mandataire_market_application: market_application) }

    it 'is a mandataire application' do
      expect(presenter.kind).to eq(:mandataire)
    end

    it 'labels it as a grouping application led by the candidate' do
      expect(presenter.kind_label).to eq('Candidature en groupement · Mandataire')
    end

    it 'uses the team icon' do
      expect(presenter.kind_icon_class).to eq('fr-icon-team-fill')
    end

    it 'links to the grouping dashboard' do
      expect(presenter.actions).to eq(%i[follow_up])
    end

    it 'stays in progress once its own part is completed' do
      market_application.update!(completed_at: Time.zone.now)

      expect(presenter.status).to eq(:in_progress)
    end

    context 'when the grouping is submitted' do
      before { grouping.update!(submitted_at: Time.zone.local(2026, 10, 21, 10), submission_mode: :full) }

      it 'is submitted to the platform' do
        expect(presenter.status).to eq(:submitted)
      end

      it 'is dated on the grouping submission' do
        expect(presenter.dated_on_label).to eq('Déposée le 21 octobre 2026')
      end

      it 'still links to the grouping dashboard' do
        expect(presenter.actions).to eq(%i[follow_up])
      end
    end

    context 'when the deadline has passed before the grouping submission' do
      before { public_market.update_column(:deadline, 1.day.ago) }

      it 'shows the deadline as passed' do
        expect(presenter.status).to eq(:deadline_passed)
      end
    end
  end

  context 'when the application is a co-traitant of a grouping' do
    let(:mandataire_application) do
      create(:market_application, public_market:, siret: '41816609600069', application_mode: :groupement)
    end
    let(:grouping) { create(:grouping, public_market:, mandataire_market_application: mandataire_application) }
    let(:market_application) { create(:market_application, public_market:, application_mode: :groupement) }

    before { create(:grouping_member, :co_traitant, grouping:, market_application:, siret: market_application.siret) }

    it 'is a co-traitant application' do
      expect(presenter.kind).to eq(:co_traitant)
    end

    it 'labels it as a grouping application as co-traitant' do
      expect(presenter.kind_label).to eq('Candidature en groupement · Co-traitant')
    end

    it 'names the mandataire of the grouping' do
      grouping.mandataire_grouping_member.update!(company_name: 'ACME BTP')

      expect(presenter.mandataire_label).to eq('Mandataire : ACME BTP')
    end

    it 'falls back on the mandataire SIRET when its company name is unknown' do
      expect(presenter.mandataire_label).to eq('Mandataire : 41816609600069')
    end

    it 'is in progress' do
      expect(presenter.status).to eq(:in_progress)
    end

    it 'can only be edited' do
      expect(presenter.actions).to eq(%i[edit])
    end

    context 'when its part is sent to the mandataire' do
      before { market_application.update!(completed_at: Time.zone.local(2026, 10, 19, 10)) }

      it 'is sent to the mandataire' do
        expect(presenter.status_label).to eq('Transmise au mandataire')
      end

      it 'is dated on its completion' do
        expect(presenter.dated_on_label).to eq('Transmise le 19 octobre 2026')
      end

      it 'can only be viewed' do
        expect(presenter.actions).to eq(%i[view])
      end
    end

    context 'when the grouping is submitted without its part' do
      before { grouping.update!(submitted_at: Time.zone.now, submission_mode: :partial) }

      it 'is submitted to the platform' do
        expect(presenter.status).to eq(:submitted)
      end

      it 'offers no action' do
        expect(presenter.actions).to be_empty
      end
    end

    context 'when the deadline has passed before the grouping submission' do
      before { public_market.update_column(:deadline, 1.day.ago) }

      it 'shows the deadline as passed' do
        expect(presenter.status).to eq(:deadline_passed)
      end

      it 'offers no action' do
        expect(presenter.actions).to be_empty
      end
    end
  end

  describe '.status_counts' do
    let(:user) { create(:user) }
    let(:market_applications) { MarketApplication.for_user(user) }

    before do
      create(:market_application, public_market:, user:)
      create(:market_application, public_market: create(:public_market, :completed), user:, completed_at: Time.zone.now)
      mandataire_application = create(:market_application, public_market: create(:public_market, :completed), user:,
        application_mode: :groupement)
      grouping = create(:grouping, public_market: mandataire_application.public_market,
        mandataire_market_application: mandataire_application)
      grouping.update!(submitted_at: Time.zone.now, submission_mode: :full)
    end

    it 'counts applications by displayed status' do
      expect(described_class.status_counts(market_applications)).to eq(in_progress: 1, completed: 2)
    end

    it 'counts a co-traitant part sent to the mandataire as completed' do
      mandataire_application = create(:market_application, public_market: create(:public_market, :completed),
        siret: '41816609600069', application_mode: :groupement)
      grouping = create(:grouping, public_market: mandataire_application.public_market,
        mandataire_market_application: mandataire_application)
      co_traitant_application = create(:market_application, public_market: mandataire_application.public_market,
        user:, application_mode: :groupement, completed_at: Time.zone.now)
      create(:grouping_member, :co_traitant, grouping:, siret: co_traitant_application.siret,
        market_application: co_traitant_application)

      expect(described_class.status_counts(market_applications)).to eq(in_progress: 1, completed: 3)
    end

    it 'counts an application whose deadline passed before its submission in neither count' do
      expired_market = create(:public_market, :completed)
      create(:market_application, public_market: expired_market, user:)
      expired_market.update_column(:deadline, 1.day.ago)

      expect(described_class.status_counts(market_applications)).to eq(in_progress: 1, completed: 2)
    end
  end
end
