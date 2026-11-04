# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResetMarketApplication, type: :interactor do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, :completed, public_market:) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe '.call' do
    context 'when application is completed' do
      let!(:manual_response) do
        create(:market_attribute_response_text_input,
          market_application:,
          source: :manual,
          value: { 'text' => 'Données manuelles' })
      end

      let!(:api_response) do
        create(:market_attribute_response_text_input,
          market_application:,
          source: :auto,
          value: { 'text' => 'Données API' })
      end

      let!(:manual_after_failure_response) do
        create(:market_attribute_response_text_input,
          market_application:,
          source: :manual_after_api_failure,
          value: { 'text' => 'Données manuelles après échec API' })
      end

      subject { described_class.call(market_application:) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'resets completed_at to nil' do
        subject
        expect(market_application.reload.completed_at).to be_nil
      end

      it 'resets sync_status to sync_pending' do
        subject
        expect(market_application.reload).to be_sync_pending
      end

      it 'resets api_fetch_status' do
        market_application.update!(api_fetch_status: { 'insee' => { 'status' => 'completed' } })
        subject
        expect(market_application.reload.api_fetch_status).to eq({})
      end

      it 'resets attests_no_exclusion_motifs' do
        market_application.update!(attests_no_exclusion_motifs: true)
        subject
        expect(market_application.reload.attests_no_exclusion_motifs).to be false
      end

      it 'destroys API responses' do
        subject
        expect(MarketAttributeResponse.exists?(api_response.id)).to be false
      end

      it 'keeps manual responses' do
        subject
        expect(MarketAttributeResponse.exists?(manual_response.id)).to be true
      end

      it 'keeps manual_after_api_failure responses' do
        subject
        expect(MarketAttributeResponse.exists?(manual_after_failure_response.id)).to be true
      end

      context 'when there is a CA response with mixed API and manual data' do
        let!(:ca_response) do
          create(:market_attribute_response_chiffre_affaires,
            market_application:,
            source: :auto,
            value: {
              'year_1' => { 'turnover' => 500_000, 'market_percentage' => 75, 'fiscal_year_end' => '2023-12-31' },
              '_api_fields' => { 'year_1' => %w[turnover fiscal_year_end] }
            })
        end

        it 'keeps the CA response record' do
          subject
          expect(MarketAttributeResponse.exists?(ca_response.id)).to be true
        end

        it 'removes API fields but preserves market_percentage' do
          subject
          reloaded = ca_response.reload
          expect(reloaded.value['year_1']['market_percentage']).to eq(75)
          expect(reloaded.value['year_1'].key?('turnover')).to be false
        end
      end

      context 'when a CA response has only API data (no manual input)' do
        let!(:pure_api_ca_response) do
          create(:market_attribute_response_chiffre_affaires,
            market_application:,
            source: :auto,
            value: {
              'year_1' => { 'turnover' => 300_000, 'fiscal_year_end' => '2023-12-31' },
              '_api_fields' => { 'year_1' => %w[turnover fiscal_year_end] }
            })
        end

        it 'destroys the CA response' do
          subject
          expect(MarketAttributeResponse.exists?(pure_api_ca_response.id)).to be false
        end
      end
    end
  end
end
