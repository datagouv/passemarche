# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MapApiData, type: :interactor do
  describe '.call' do
    let(:public_market) { create(:public_market, :completed) }
    let(:market_application) { create(:market_application, public_market:) }
    let(:resource) { Resource.new(siret: '41816609600069', category: 'PME') }
    let(:bundled_data) { BundledData.new(data: resource, context: {}) }
    let(:api_name) { 'Insee' }

    subject do
      described_class.call(
        market_application:,
        api_name:,
        bundled_data:
      )
    end

    context 'when public_market has attributes from the API' do
      let!(:siret_attribute) do
        create(:market_attribute, :text_input, :from_api,
          key: 'identite_entreprise_identification_siret',
          api_name: 'Insee',
          api_key: 'siret',
          public_markets: [public_market])
      end

      let!(:category_attribute) do
        create(:market_attribute, :text_input, :from_api,
          key: 'identite_entreprise_identification_categorie',
          api_name: 'Insee',
          api_key: 'category',
          public_markets: [public_market])
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates market_attribute_responses for each API field' do
        expect { subject }.to change { market_application.market_attribute_responses.count }.by(2)
      end

      it 'populates the SIRET response with correct value' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: siret_attribute)
        expect(response.text).to eq('41816609600069')
      end

      it 'populates the category response with correct value' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: category_attribute)
        expect(response.text).to eq('PME')
      end

      it 'sets the correct STI type for responses' do
        subject
        responses = market_application.market_attribute_responses.reload
        expect(responses.map(&:type).uniq).to eq(['TextInput'])
      end

      it 'sets source to auto for new responses' do
        subject
        responses = market_application.market_attribute_responses.reload
        expect(responses.map(&:source).uniq).to eq(['auto'])
      end

      context 'when responses already exist' do
        before do
          create(:market_attribute_response,
            market_application:,
            market_attribute: siret_attribute,
            value: { 'text' => 'old_value' })
        end

        it 'updates existing responses instead of creating new ones' do
          expect { subject }.to change { market_application.market_attribute_responses.count }.by(1)
        end

        it 'updates the value of existing response' do
          subject
          response = market_application.market_attribute_responses.find_by(market_attribute: siret_attribute)
          expect(response.text).to eq('41816609600069')
        end

        it 'sets source to auto for updated responses' do
          subject
          response = market_application.market_attribute_responses.find_by(market_attribute: siret_attribute)
          expect(response.source).to eq('auto')
        end
      end

      context 'when response has manual_after_api_failure source' do
        before do
          create(:market_attribute_response,
            market_application:,
            market_attribute: siret_attribute,
            value: { 'text' => 'manually_entered' },
            source: :manual_after_api_failure)
        end

        it 'does not change source from manual_after_api_failure' do
          subject
          response = market_application.market_attribute_responses.find_by(market_attribute: siret_attribute)
          expect(response.source).to eq('manual_after_api_failure')
        end

        it 'still updates the value even with manual_after_api_failure source' do
          subject
          response = market_application.market_attribute_responses.find_by(market_attribute: siret_attribute)
          expect(response.text).to eq('41816609600069')
        end
      end

      context 'when resource has nil values' do
        let(:resource) { Resource.new(siret: '41816609600069', category: nil) }

        it 'succeeds' do
          expect(subject).to be_success
        end

        it 'stores nil values correctly' do
          subject
          response = market_application.market_attribute_responses.find_by(market_attribute: category_attribute)
          expect(response.text).to be_nil
        end
      end
    end

    context 'when public_market has no attributes from this API' do
      let!(:other_attribute) do
        create(:market_attribute, :text_input, :from_api,
          key: 'other_field',
          api_name: 'OtherAPI',
          api_key: 'other',
          public_markets: [public_market])
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'does not create any responses' do
        expect { subject }.not_to change { market_application.market_attribute_responses.count }
      end
    end

    context 'when market_application is not provided' do
      subject do
        described_class.call(
          api_name:,
          bundled_data:
        )
      end

      it 'succeeds without doing anything' do
        expect(subject).to be_success
      end
    end

    context 'when bundled_data is missing' do
      subject do
        described_class.call(
          market_application:,
          api_name:
        )
      end

      it 'fails with an error' do
        expect(subject).to be_failure
      end

      it 'sets an error message' do
        result = subject
        expect(result.error).to be_present
      end
    end
  end
end
