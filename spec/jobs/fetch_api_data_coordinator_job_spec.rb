# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FetchApiDataCoordinatorJob, type: :job do
  let(:public_market) { create(:public_market, :completed) }
  let(:market_application) { create(:market_application, public_market:) }

  describe '#perform' do
    context 'with market that has all API attributes' do
      it 'spawns all individual API fetch jobs' do
        # Ensure market has attributes from all APIs
        insee_attr = create(:market_attribute, api_name: 'insee')
        rne_attr = create(:market_attribute, api_name: 'rne')
        dgfip_attr = create(:market_attribute, api_name: 'attestations_fiscales')
        dgfip_chiffres_affaires_attr = create(:market_attribute, api_name: 'dgfip_chiffres_affaires')
        qualibat_attr = create(:market_attribute, api_name: 'qualibat')
        public_market.market_attributes << [insee_attr, rne_attr, dgfip_attr, dgfip_chiffres_affaires_attr, qualibat_attr]

        expect(FetchInseeDataJob).to receive(:perform_later).with(market_application.id)
        expect(FetchRneDataJob).to receive(:perform_later).with(market_application.id)
        expect(FetchDgfipDataJob).to receive(:perform_later).with(market_application.id)
        expect(FetchChiffresAffairesDataJob).to receive(:perform_later).with(market_application.id)
        expect(FetchQualibatDataJob).to receive(:perform_later).with(market_application.id)

        described_class.perform_now(market_application.id)
      end

      it 'has all defined API jobs in constant' do
        expect(described_class::API_JOBS.count).to eq(7)
        expect(described_class::API_JOBS)
          .to include(FetchInseeDataJob, FetchRneDataJob, FetchDgfipDataJob, FetchQualibatDataJob, FetchQualifelecDataJob, FetchProbtpDataJob, FetchChiffresAffairesDataJob)
      end
    end

    context 'with market that has subset of API attributes' do
      it 'only spawns jobs for APIs the market uses' do
        # Market only has insee and rne attributes
        insee_attr = create(:market_attribute, api_name: 'insee')
        rne_attr = create(:market_attribute, api_name: 'rne')
        public_market.market_attributes << [insee_attr, rne_attr]

        expect(FetchInseeDataJob).to receive(:perform_later).with(market_application.id)
        expect(FetchRneDataJob).to receive(:perform_later).with(market_application.id)
        expect(FetchDgfipDataJob).not_to receive(:perform_later)
        expect(FetchQualibatDataJob).not_to receive(:perform_later)
        expect(FetchChiffresAffairesDataJob).not_to receive(:perform_later)

        described_class.perform_now(market_application.id)
      end
    end

    context 'with market that has no API attributes' do
      it 'does not spawn any API jobs' do
        # Market only has manual fields (no api_name)
        manual_attr = create(:market_attribute, api_name: nil)
        public_market.market_attributes << [manual_attr]

        expect(FetchInseeDataJob).not_to receive(:perform_later)
        expect(FetchRneDataJob).not_to receive(:perform_later)
        expect(FetchDgfipDataJob).not_to receive(:perform_later)
        expect(FetchQualibatDataJob).not_to receive(:perform_later)
        expect(FetchChiffresAffairesDataJob).not_to receive(:perform_later)

        described_class.perform_now(market_application.id)
      end
    end

    context 'when an error occurs spawning jobs' do
      before do
        # Ensure market has insee attribute so the job would be spawned
        insee_attr = create(:market_attribute, api_name: 'insee')
        public_market.market_attributes << [insee_attr]

        allow(FetchInseeDataJob)
          .to receive(:perform_later).and_raise(StandardError, 'Queue error')
      end

      it 'logs the error and re-raises' do
        allow(Rails.logger).to receive(:error)

        expect do
          described_class.perform_now(market_application.id)
        end.to raise_error(StandardError, 'Queue error')

        expect(Rails.logger).to have_received(:error)
          .with(/Error in coordinator for market application #{market_application.id}: Queue error/)
      end
    end

    context 'when market application does not exist' do
      it 'raises ActiveRecord::RecordNotFound' do
        non_existent_id = 999_999

        expect do
          described_class.perform_now(non_existent_id)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
