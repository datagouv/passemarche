# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateMarketApplication, type: :interactor do
  let(:editor) { create(:editor) }
  let(:siret) { '73282932000074' }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe '.call' do
    context 'when valid' do
      let(:public_market) { create(:public_market, :completed, editor:) }

      subject { described_class.call(public_market:, siret:) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates a persisted market application' do
        result = subject
        expect(result.market_application).to be_persisted
        expect(result.market_application.public_market).to eq(public_market)
        expect(result.market_application.siret).to eq(siret)
        expect(result.market_application.identifier).to match(/^VR-\d{4}-[A-Z0-9]{12}$/)
      end
    end

    context 'when market deadline has passed' do
      let(:public_market) { create(:public_market, :completed, editor:, deadline: 1.day.ago) }

      subject { described_class.call(public_market:, siret:) }

      it 'succeeds and creates an application' do
        expect(subject).to be_success
        expect(subject.market_application).to be_persisted
      end
    end

    context 'when market deadline has passed with a completed application' do
      let(:public_market) { create(:public_market, :completed, editor:, deadline: 1.day.ago) }
      let!(:existing) { create(:market_application, :completed, public_market:, siret:) }

      subject { described_class.call(public_market:, siret:) }

      it 'succeeds and returns the existing application without resetting' do
        expect(subject).to be_success
        expect(subject.market_application).to eq(existing)
        expect(existing.reload).to be_completed
      end
    end

    context 'when an in-progress application already exists for same SIRET/market' do
      let(:public_market) { create(:public_market, :completed, editor:) }
      let!(:existing_application) { create(:market_application, public_market:, siret:) }

      subject { described_class.call(public_market:, siret:) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'returns the existing application' do
        expect(subject.market_application).to eq(existing_application)
      end

      it 'does not create a new application' do
        expect { subject }.not_to change(MarketApplication, :count)
      end
    end

    context 'when a completed application exists (re-candidature)' do
      let(:public_market) { create(:public_market, :completed, editor:) }
      let!(:existing_application) { create(:market_application, :completed, public_market:, siret:) }

      let!(:manual_response) do
        create(:market_attribute_response_text_input,
          market_application: existing_application,
          source: :manual,
          value: { 'text' => 'Données manuelles' })
      end

      let!(:api_response) do
        create(:market_attribute_response_text_input,
          market_application: existing_application,
          source: :auto,
          value: { 'text' => 'Données API' })
      end

      subject { described_class.call(public_market:, siret:) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'returns the reset application' do
        expect(subject.market_application).to eq(existing_application)
      end

      it 'resets completed_at' do
        subject
        expect(existing_application.reload.completed_at).to be_nil
      end

      it 'keeps manual responses' do
        subject
        expect(MarketAttributeResponse.exists?(manual_response.id)).to be true
      end

      it 'destroys API responses' do
        subject
        expect(MarketAttributeResponse.exists?(api_response.id)).to be false
      end

      it 'does not create a new application' do
        expect { subject }.not_to change(MarketApplication, :count)
      end
    end

    context 'when application_mode is not specified' do
      let(:public_market) { create(:public_market, :completed, editor:) }

      subject { described_class.call(public_market:, siret:) }

      it 'leaves the mode unset (not yet chosen by the candidate)' do
        expect(subject.market_application.application_mode).to be_nil
      end

      it 'finds an existing application regardless of its solo/nil mode' do
        existing = create(:market_application, public_market:, siret:, application_mode: :solo)

        expect(subject.market_application).to eq(existing)
      end
    end

    context 'when a solo application already exists and a groupement application is requested' do
      let(:public_market) { create(:public_market, :completed, editor:) }
      let!(:solo_application) { create(:market_application, public_market:, siret:, application_mode: :solo) }

      subject { described_class.call(public_market:, siret:, application_mode: :groupement) }

      it 'creates a distinct groupement application' do
        expect { subject }.to change(MarketApplication, :count).by(1)
      end

      it 'does not touch the existing solo application' do
        subject
        expect(solo_application.reload).to be_solo
      end

      it 'returns the new groupement application' do
        expect(subject.market_application).not_to eq(solo_application)
        expect(subject.market_application).to be_groupement
      end
    end

    context 'when a groupement application already exists for the same SIRET/market' do
      let(:public_market) { create(:public_market, :completed, editor:) }
      let!(:existing) { create(:market_application, public_market:, siret:, application_mode: :groupement) }

      subject { described_class.call(public_market:, siret:, application_mode: :groupement) }

      it 'returns the existing application without creating a new one' do
        expect { subject }.not_to change(MarketApplication, :count)
        expect(subject.market_application).to eq(existing)
      end
    end

    context 'when a completed solo application exists and a groupement application is requested' do
      let(:public_market) { create(:public_market, :completed, editor:) }
      let!(:completed_solo) { create(:market_application, :completed, public_market:, siret:, application_mode: :solo) }

      subject { described_class.call(public_market:, siret:, application_mode: :groupement) }

      it 'does not reset the completed solo application' do
        subject
        expect(completed_solo.reload).to be_completed
      end

      it 'creates a new groupement application instead' do
        expect { subject }.to change(MarketApplication, :count).by(1)
        expect(subject.market_application).not_to eq(completed_solo)
      end
    end

    context 'when SIRET is missing' do
      let(:public_market) { create(:public_market, :completed, editor:) }

      subject { described_class.call(public_market:, siret: nil) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'has presence validation error' do
        expect(subject.errors[:siret]).to be_present
      end
    end

    context 'when SIRET validation fails' do
      let(:public_market) { create(:public_market, :completed, editor:) }
      let(:invalid_siret) { '12345678901234' }

      before do
        allow(SiretValidator).to receive(:valid?).with(public_market.siret).and_return(true)
        allow(SiretValidator).to receive(:valid?).with(invalid_siret).and_return(false)
      end

      subject { described_class.call(public_market:, siret: invalid_siret) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'has validation errors' do
        expect(subject.errors[:siret]).to be_present
      end
    end
  end
end
