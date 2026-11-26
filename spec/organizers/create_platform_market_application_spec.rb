# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreatePlatformMarketApplication, type: :organizer do
  let(:editor) { create(:editor) }
  let(:siret) { '73282932000074' }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe '.call' do
    let(:public_market) { create(:public_market, :completed, :multi_type, editor:) }
    let(:works_type) { MarketType.find_by!(code: 'works') }
    let(:services_type) { MarketType.find_by!(code: 'services') }
    let(:works_lot) { public_market.lots.find_by!(name: 'Gros œuvre') }
    let(:other_works_lot) { public_market.lots.find_by!(name: 'Charpente') }
    let(:services_lot) { public_market.lots.find_by!(name: 'Prestations SI') }

    before { allow(FetchApiDataCoordinatorJob).to receive(:perform_later) }

    context 'on a new application' do
      subject { described_class.call(public_market:, siret:, platform_application_mode: 'solo', lot_ids: [works_lot.id, services_lot.id]) }

      it 'declares the transmitted lots and locks them' do
        application = subject.market_application

        expect(application.lots).to contain_exactly(works_lot, services_lot)
        expect(application).to be_lots_locked
      end

      it 'does not flag a lot change by the platform' do
        expect(subject.market_application.lots_changed_by_platform_at).to be_nil
      end

      it 'creates an individual application so that the candidate cannot switch to a grouping' do
        expect(subject.market_application).to be_solo
      end
    end

    context 'without the application mode' do
      subject { described_class.call(public_market:, siret:, lot_ids: [works_lot.id]) }

      it 'fails without creating the application' do
        expect { subject }.not_to change(MarketApplication, :count)
        expect(subject.errors[:application_mode]).to include(
          I18n.t('api.errors.platform_application_mode_invalid')
        )
      end
    end

    context 'with an unknown application mode' do
      subject { described_class.call(public_market:, siret:, platform_application_mode: 'mixte', lot_ids: [works_lot.id]) }

      it 'fails without creating the application' do
        expect { subject }.not_to change(MarketApplication, :count)
        expect(subject.errors[:application_mode]).to be_present
      end
    end

    context 'for a grouping' do
      subject do
        described_class.call(public_market:, siret:, platform_application_mode: 'groupement', lot_ids: [works_lot.id])
      end

      it 'ignores the lots and lets the candidate choose the application mode' do
        application = subject.market_application

        expect(subject).to be_success
        expect(application.lots).to be_empty
        expect(application).not_to be_lots_locked
        expect(application.application_mode).to be_nil
      end
    end

    context 'on an application whose mode has not been chosen yet' do
      let!(:existing_application) { create(:market_application, public_market:, siret:) }

      it 'turns it into an individual application' do
        described_class.call(public_market:, siret:, platform_application_mode: 'solo', lot_ids: [works_lot.id])

        expect(existing_application.reload).to be_solo
        expect(existing_application.lots).to contain_exactly(works_lot)
      end
    end

    context 'with a lot outside the market' do
      let(:foreign_lot) { create(:lot) }

      subject { described_class.call(public_market:, siret:, platform_application_mode: 'solo', lot_ids: [works_lot.id, foreign_lot.id]) }

      it 'fails without creating the application' do
        expect { subject }.not_to change(MarketApplication, :count)
        expect(subject).to be_failure
        expect(subject.errors[:lot_ids]).to include(
          I18n.t('activemodel.errors.models.lot_selection_policy.attributes.base.lot_outside_market')
        )
      end
    end

    context 'with an empty list of lots' do
      subject { described_class.call(public_market:, siret:, platform_application_mode: 'solo', lot_ids: []) }

      it 'fails without creating the application' do
        expect { subject }.not_to change(MarketApplication, :count)
        expect(subject.errors[:lot_ids]).to be_present
      end
    end

    context 'on an in-progress application (re-candidature with other lots)' do
      let!(:existing_application) do
        create(:market_application, public_market:, siret:, lots: [works_lot], lots_locked: true)
      end
      let!(:works_attribute) do
        create(:market_attribute, public_markets: [public_market], market_types: [works_type])
      end
      let!(:manual_response) do
        create(:market_attribute_response_text_input, market_application: existing_application,
          market_attribute: works_attribute, source: :manual, value: { 'text' => 'Réponse saisie' })
      end

      it 'replaces the lot selection and keeps the answers of the remaining lot types' do
        result = described_class.call(public_market:, siret:, platform_application_mode: 'solo', lot_ids: [other_works_lot.id])

        expect(result.market_application).to eq(existing_application)
        expect(existing_application.reload.lots).to contain_exactly(other_works_lot)
        expect(MarketAttributeResponse.exists?(manual_response.id)).to be true
      end

      it 'does not flag a lot change when no new lot type is added' do
        described_class.call(public_market:, siret:, platform_application_mode: 'solo', lot_ids: [other_works_lot.id])

        expect(existing_application.reload.lots_changed_by_platform_at).to be_nil
      end

      it 'flags the lot change when a lot of a new type is added' do
        described_class.call(public_market:, siret:, platform_application_mode: 'solo', lot_ids: [works_lot.id, services_lot.id])

        expect(existing_application.reload.lots_changed_by_platform_at).to be_present
      end

      it 'fetches the APIs of the new lot type once the API step has already run' do
        create(:market_attribute, public_markets: [public_market], market_types: [services_type],
          api_name: 'insee', api_key: 'siret')
        existing_application.update!(api_fetch_status: { 'probtp' => { 'status' => 'completed' } })

        described_class.call(public_market:, siret:, platform_application_mode: 'solo', lot_ids: [works_lot.id, services_lot.id])

        expect(FetchApiDataCoordinatorJob).to have_received(:perform_later).with(existing_application.id, ['insee'])
      end

      it 'does not fetch any API while the API step has not run yet' do
        create(:market_attribute, public_markets: [public_market], market_types: [services_type],
          api_name: 'insee', api_key: 'siret')

        described_class.call(public_market:, siret:, platform_application_mode: 'solo', lot_ids: [works_lot.id, services_lot.id])

        expect(FetchApiDataCoordinatorJob).not_to have_received(:perform_later)
      end

      it 'fetches the APIs of the new lot type once the candidate has started the form without any API so far' do
        create(:market_attribute, public_markets: [public_market], market_types: [services_type],
          api_name: 'insee', api_key: 'siret')
        existing_application.update!(started_at: 1.hour.ago)

        described_class.call(public_market:, siret:, platform_application_mode: 'solo', lot_ids: [works_lot.id, services_lot.id])

        expect(FetchApiDataCoordinatorJob).to have_received(:perform_later).with(existing_application.id, ['insee'])
      end
    end

    context 'on a completed application (re-candidature with other lots)' do
      let!(:existing_application) do
        create(:market_application, :completed, public_market:, siret:, lots: [works_lot], lots_locked: true)
      end

      it 'resets the application and replaces the lot selection' do
        described_class.call(public_market:, siret:, platform_application_mode: 'solo', lot_ids: [services_lot.id])

        expect(existing_application.reload).not_to be_completed
        expect(existing_application.lots).to contain_exactly(services_lot)
      end
    end

    context 'on a completed application once the deadline has passed' do
      let!(:existing_application) do
        create(:market_application, :completed, public_market:, siret:, lots: [works_lot], lots_locked: true)
      end

      before { public_market.update!(deadline: 1.day.ago) }

      it 'refuses other lots and keeps the submitted ones' do
        result = described_class.call(public_market:, siret:, platform_application_mode: 'solo', lot_ids: [services_lot.id])

        expect(result).to be_failure
        expect(result.errors[:lot_ids]).to include(I18n.t('api.errors.platform_lots_after_deadline'))
        expect(existing_application.reload).to be_completed
        expect(existing_application.lots).to contain_exactly(works_lot)
      end

      it 'refuses a malformed list even when it contains the submitted lots' do
        result = described_class.call(public_market:, siret:, platform_application_mode: 'solo', lot_ids: [works_lot.id, 'abc'])

        expect(result).to be_failure
        expect(result.errors[:lot_ids]).to be_present
      end

      it 'returns the application when the same lots are transmitted again' do
        result = described_class.call(public_market:, siret:, platform_application_mode: 'solo', lot_ids: [works_lot.id])

        expect(result).to be_success
        expect(result.market_application).to eq(existing_application)
      end
    end

    context 'on an in-progress application that fails the full validation' do
      let!(:existing_application) do
        create(:market_application, public_market:, siret:, lots: [works_lot], lots_locked: true)
      end

      before { existing_application.update_column(:provider_user_id, 'x' * 256) }

      it 'still replaces the lot selection' do
        result = described_class.call(public_market:, siret:, platform_application_mode: 'solo', lot_ids: [services_lot.id])

        expect(result).to be_success
        expect(existing_application.reload.lots).to contain_exactly(services_lot)
      end

      context 'once the API step has run' do
        before do
          create(:market_attribute, public_markets: [public_market], market_types: [works_type],
            api_name: 'probtp', api_key: 'siret')
          create(:market_attribute, public_markets: [public_market], market_types: [services_type],
            api_name: 'insee', api_key: 'siret')
          existing_application.update_column(:api_fetch_status, { 'probtp' => { 'status' => 'completed' } })
        end

        it 'adds a lot type requiring a new API' do
          result = described_class.call(public_market:, siret:, platform_application_mode: 'solo', lot_ids: [works_lot.id, services_lot.id])

          expect(result).to be_success
          expect(existing_application.reload.api_fetch_status.keys).to contain_exactly('probtp', 'insee')
        end

        it 'removes the lot type of an API already fetched' do
          result = described_class.call(public_market:, siret:, platform_application_mode: 'solo', lot_ids: [services_lot.id])

          expect(result).to be_success
          expect(existing_application.reload.api_fetch_status.keys).not_to include('probtp')
        end
      end
    end

    context 'when a later call does not transmit any lot' do
      let!(:existing_application) do
        create(:market_application, public_market:, siret:, lots: [works_lot], lots_locked: true,
          lots_changed_by_platform_at: 1.hour.ago)
      end

      it 'keeps the lots but lets the candidate change them in Passe Marché' do
        described_class.call(public_market:, siret:)

        expect(existing_application.reload.lots).to contain_exactly(works_lot)
        expect(existing_application).not_to be_lots_locked
        expect(existing_application.lots_changed_by_platform_at).to be_nil
      end
    end
  end
end
