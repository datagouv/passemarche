# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiFetchable do
  let(:dummy_api_service) { class_double('DummyApiService') }

  let(:dummy_job_class) do
    service = dummy_api_service
    Class.new(ApplicationJob) do
      include ApiFetchable

      define_singleton_method(:api_name) { 'dummy_api' }
      define_singleton_method(:api_service) { service }
    end
  end

  let(:public_market) { create(:public_market, :completed) }
  let(:siret) { '41816609600069' }
  let(:market_application) { create(:market_application, public_market:, siret:, api_fetch_status: {}) }

  describe 'class methods' do
    context 'when not overridden' do
      let(:incomplete_job_class) do
        Class.new(ApplicationJob) do
          include ApiFetchable
        end
      end

      it 'raises NotImplementedError for api_name' do
        expect { incomplete_job_class.api_name }.to raise_error(NotImplementedError, /must implement \.api_name/)
      end

      it 'raises NotImplementedError for api_service' do
        expect { incomplete_job_class.api_service }.to raise_error(NotImplementedError, /must implement \.api_service/)
      end
    end

    context 'when properly overridden' do
      it 'returns the api_name' do
        expect(dummy_job_class.api_name).to eq('dummy_api')
      end

      it 'returns the api_service' do
        expect(dummy_job_class.api_service).to eq(dummy_api_service)
      end
    end
  end

  describe 'queue configuration' do
    it 'sets the queue to :default' do
      expect(dummy_job_class.queue_name).to eq('default')
    end
  end

  describe '#perform' do
    let(:job) { dummy_job_class.new }

    context 'when siret is blank' do
      before do
        market_application.update_column(:siret, nil)
      end

      it 'does not call the API service' do
        expect(dummy_api_service).not_to receive(:call)
        job.perform(market_application.id)
      end
    end

    context 'when siret is present' do
      let(:result) { instance_double('Interactor::Context', success?: true) }

      before do
        allow(dummy_api_service).to receive(:call).and_return(result)
      end

      it 'calls the API service with correct parameters' do
        expect(dummy_api_service).to receive(:call).with(
          params: { siret: market_application.siret },
          market_application:
        )
        job.perform(market_application.id)
      end
    end

    context 'when market_application is not found' do
      it 'raises ActiveRecord::RecordNotFound' do
        expect { job.perform(-1) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'error handling' do
    let(:job) { dummy_job_class.new }
    let(:error) { StandardError.new('API Error') }

    before do
      allow(dummy_api_service).to receive(:call).and_raise(error)
      allow(Rails.logger).to receive(:error)
    end

    it 'logs the error' do
      expect { job.perform(market_application.id) }.to raise_error(StandardError)

      expect(Rails.logger).to have_received(:error).with(/Error fetching dummy_api data/)
    end

    it 'updates the API status to failed' do
      expect { job.perform(market_application.id) }.to raise_error(StandardError)

      api_status = market_application.reload.api_fetch_status['dummy_api']
      expect(api_status['status']).to eq('failed')
    end

    it 're-raises the error' do
      expect { job.perform(market_application.id) }.to raise_error(StandardError, 'API Error')
    end
  end

  describe 'result handling' do
    let(:job) { dummy_job_class.new }

    context 'when API call succeeds' do
      let(:result) { instance_double('Interactor::Context', success?: true) }

      before do
        allow(dummy_api_service).to receive(:call).and_return(result)
      end

      it 'updates status to completed' do
        job.perform(market_application.id)

        api_status = market_application.reload.api_fetch_status['dummy_api']
        expect(api_status['status']).to eq('completed')
      end
    end

    context 'when API call fails' do
      let(:result) { instance_double('Interactor::Context', success?: false) }

      before do
        allow(dummy_api_service).to receive(:call).and_return(result)
      end

      it 'updates status to failed' do
        job.perform(market_application.id)

        api_status = market_application.reload.api_fetch_status['dummy_api']
        expect(api_status['status']).to eq('failed')
      end
    end
  end

  describe 'API response cleanup on failure' do
    let(:job) { dummy_job_class.new }
    let(:result) { instance_double('Interactor::Context', success?: false) }
    let(:market_attribute) do
      create(:market_attribute, :text_input, api_name: 'dummy_api').tap do |attr|
        attr.public_markets << public_market
      end
    end
    let!(:response) do
      create(:market_attribute_response_text_input,
        market_application:,
        market_attribute:,
        source: :auto).tap do |r|
        r.text = 'some data'
        r.save!
      end
    end

    before do
      allow(dummy_api_service).to receive(:call).and_return(result)
    end

    it 'clears the text on auto-sourced responses' do
      job.perform(market_application.id)

      expect(response.reload.text).to be_nil
    end

    it 'marks responses as manual_after_api_failure' do
      job.perform(market_application.id)

      expect(response.reload.source).to eq('manual_after_api_failure')
    end
  end
end
