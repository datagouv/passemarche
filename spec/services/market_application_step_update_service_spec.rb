# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketApplicationStepUpdateService do
  include ApiResponses::InseeResponses
  include ApiResponses::RneResponses

  let(:public_market) { create(:public_market, :completed) }
  let(:market_application) { create(:market_application, public_market:, siret: '41816609600069') }
  let(:token) { 'test_token_123' }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }

  before do
    allow(Rails.application.credentials).to receive(:api_entreprise).and_return(
      OpenStruct.new(base_url:, token:)
    )
  end

  describe '.call' do
    context 'with api_data_recovery_status step' do
      let(:params) { {} }

      it 'returns success' do
        result = described_class.call(market_application, :api_data_recovery_status, params)

        expect(result[:success]).to be true
      end

      it 'has no flash messages' do
        result = described_class.call(market_application, :api_data_recovery_status, params)

        expect(result[:flash_messages]).to be_empty
      end

      it 'is a simple passthrough (API calls happen in background jobs)' do
        # API calls are enqueued by CompanyIdentificationsController
        result = described_class.call(market_application, :api_data_recovery_status, params)

        expect(result[:success]).to be true
        expect(result[:market_application]).to eq(market_application)
      end
    end

    context 'with generic step' do
      let(:step) { :contact }

      it 'returns success when validation passes' do
        result = described_class.call(market_application, step, {})

        expect(result[:success]).to be true
      end

      it 'reloads responses after save' do
        expect(market_application.market_attribute_responses).to receive(:reload)

        described_class.call(market_application, step, {})
      end

      context 'when the application belongs to a grouping member' do
        let(:grouping) { create(:grouping, public_market:, mandataire_market_application: market_application) }
        let(:member) { grouping.mandataire_grouping_member }

        before do
          allow(SiretValidator).to receive(:valid?).and_return(true)
          member.update!(status: :to_prepare)
        end

        it 'marks the grouping_member as in_progress' do
          market_application.reload

          expect { described_class.call(market_application, step, {}) }
            .to change { member.reload.status_in_progress? }.from(false).to(true)
        end
      end

      context 'when a response already exists but form submits with blank id' do
        let(:market_attribute) do
          create(:market_attribute, :radio_with_file_and_text,
            subcategory_key: step.to_s,
            category_key: 'test_category')
        end

        let!(:existing_response) do
          create(:market_attribute_response_radio_with_file_and_text,
            market_application:,
            market_attribute:,
            value: { 'radio_choice' => 'no' })
        end

        let(:params) do
          ActionController::Parameters.new(
            market_attribute_responses_attributes: {
              '0' => {
                'id' => '',
                'market_attribute_id' => market_attribute.id.to_s,
                'type' => 'RadioWithFileAndText',
                'radio_choice' => 'yes',
                'text' => ''
              }
            }
          ).permit!
        end

        before do
          public_market.market_attributes << market_attribute
        end

        it 'updates the existing response instead of raising a unique constraint error' do
          result = described_class.call(market_application, step, params)

          expect(result[:success]).to be true
          expect(existing_response.reload.value['radio_choice']).to eq('yes')
        end
      end
    end

    context 'with summary step' do
      before do
        allow(CompleteMarketApplication).to receive(:call)
          .and_return(double(success?: true))
      end

      it 'calls CompleteMarketApplication organizer' do
        expect(CompleteMarketApplication).to receive(:call).with(market_application:)

        described_class.call(market_application, :summary, {})
      end

      it 'returns success with redirect' do
        result = described_class.call(market_application, :summary, {})

        expect(result[:success]).to be true
        expect(result[:redirect]).to eq(:sync_status)
      end

      context 'when completion fails' do
        before do
          allow(CompleteMarketApplication).to receive(:call)
            .and_return(double(success?: false, message: 'Completion error'))
        end

        it 'returns failure' do
          result = described_class.call(market_application, :summary, {})

          expect(result[:success]).to be false
        end

        it 'includes error message in flash' do
          result = described_class.call(market_application, :summary, {})

          expect(result[:flash_messages][:alert]).to eq('Completion error')
        end
      end

      context 'when an exception occurs' do
        before do
          allow(CompleteMarketApplication).to receive(:call)
            .and_raise(ActiveRecord::RecordInvalid.new(market_application))
        end

        it 'returns failure' do
          result = described_class.call(market_application, :summary, {})

          expect(result[:success]).to be false
        end

        it 'logs the error' do
          expect(Rails.logger).to receive(:error)
            .with(/Error completing market application/)

          described_class.call(market_application, :summary, {})
        end

        it 'includes generic error message in flash' do
          result = described_class.call(market_application, :summary, {})

          expect(result[:flash_messages][:alert]).to be_present
        end
      end
    end

    context 'with summary step for a grouping member application' do
      let(:market_application) do
        create(:market_application, public_market:, siret: '41816609600069', application_mode: :groupement)
      end
      let(:grouping) { create(:grouping, public_market:, mandataire_market_application: market_application) }

      before do
        allow(SiretValidator).to receive(:valid?).and_return(true)
        grouping
      end

      it 'calls Candidate::CompleteGroupingMember instead of CompleteMarketApplication' do
        expect(Candidate::CompleteGroupingMember).to receive(:call).with(market_application:).and_call_original
        expect(CompleteMarketApplication).not_to receive(:call)

        described_class.call(market_application, :summary, {})
      end

      it 'returns success without a sync_status redirect' do
        result = described_class.call(market_application, :summary, {})

        expect(result[:success]).to be true
        expect(result[:redirect]).to be_nil
      end

      context 'when already completed' do
        before { market_application.complete! }

        it 'returns failure' do
          result = described_class.call(market_application, :summary, {})

          expect(result[:success]).to be false
        end
      end
    end
  end
end
