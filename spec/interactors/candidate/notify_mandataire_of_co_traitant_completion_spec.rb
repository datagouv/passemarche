# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::NotifyMandataireOfCoTraitantCompletion, type: :interactor do
  let(:public_market) { create(:public_market, :completed) }
  let(:mandataire_application) do
    create(:market_application, public_market:, siret: '73282932000074', application_mode: :groupement,
      user: create(:user, email: 'mandataire@example.com'))
  end
  let(:grouping) { create(:grouping, public_market:, mandataire_market_application: mandataire_application) }

  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  describe '.call' do
    subject(:result) { described_class.call(market_application:) }

    context 'when the application belongs to a co_traitant' do
      let(:market_application) do
        create(:market_application, public_market:, siret: '80245139600021', application_mode: :groupement)
      end
      let!(:co_traitant) do
        create(:grouping_member, :co_traitant, grouping:, siret: market_application.siret, market_application:)
      end

      it 'notifies the mandataire with a link to its dashboard' do
        dashboard_url = Rails.application.routes.url_helpers.grouping_dashboard_candidate_market_application_url(
          mandataire_application.identifier
        )

        expect { result }.to have_enqueued_mail(GroupingMemberCompletionMailer, :completed).with(co_traitant, 'mandataire@example.com', dashboard_url)
      end

      context 'when the co_traitant had already transmitted its application' do
        subject(:result) { described_class.call(market_application:, already_transmitted: true) }

        it 'notifies the mandataire of the modification' do
          expect { result }.to have_enqueued_mail(GroupingMemberCompletionMailer, :modified)
        end
      end
    end

    context 'when the mandataire has no known user' do
      let(:market_application) do
        create(:market_application, public_market:, siret: '80245139600021', application_mode: :groupement)
      end

      before do
        mandataire_application.update!(user: nil)
        create(:grouping_member, :co_traitant, grouping:, siret: market_application.siret, market_application:)
      end

      it 'does not notify anyone' do
        expect { result }.not_to have_enqueued_mail(GroupingMemberCompletionMailer, :completed)
      end
    end

    context 'when the application belongs to the mandataire' do
      let(:market_application) { mandataire_application }

      before { grouping }

      it 'does not notify anyone' do
        expect { result }.not_to have_enqueued_mail(GroupingMemberCompletionMailer, :completed)
      end
    end

    context 'when the application is solo' do
      let(:market_application) { create(:market_application, public_market:, application_mode: :solo) }

      it 'does not notify anyone' do
        expect { result }.not_to have_enqueued_mail(GroupingMemberCompletionMailer, :completed)
      end
    end
  end
end
