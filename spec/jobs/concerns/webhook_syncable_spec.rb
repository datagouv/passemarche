# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebhookSyncable do
  let(:dummy_class) do
    Class.new do
      include WebhookSyncable
    end
  end

  let(:editor) do
    create(:editor,
      completion_webhook_url: 'https://example.com/webhook',
      webhook_secret: 'secret123')
  end

  let(:entity) do
    instance_double('Entity',
      sync_completed?: false,
      editor:,
      update!: true)
  end

  subject(:instance) { dummy_class.new }

  describe '#skip_delivery?' do
    context 'when entity is sync_completed' do
      let(:entity) { instance_double('Entity', sync_completed?: true) }

      it 'returns true' do
        expect(instance.skip_delivery?(entity)).to be true
      end
    end

    context 'when entity is not sync_completed' do
      let(:entity) { instance_double('Entity', sync_completed?: false) }

      it 'returns false' do
        expect(instance.skip_delivery?(entity)).to be false
      end
    end
  end

  describe '#before_delivery_callback' do
    it 'updates entity sync_status to sync_processing' do
      expect(entity).to receive(:update!).with(sync_status: :sync_processing)

      instance.before_delivery_callback(entity)
    end
  end

  describe '#entity_webhook_url' do
    it 'returns the editor completion_webhook_url' do
      expect(instance.entity_webhook_url(entity)).to eq('https://example.com/webhook')
    end
  end

  describe '#entity_webhook_secret' do
    it 'returns the editor webhook_secret' do
      expect(instance.entity_webhook_secret(entity)).to eq('secret123')
    end
  end

  describe '#on_success_callback' do
    it 'updates entity sync_status to sync_completed' do
      expect(entity).to receive(:update!).with(sync_status: :sync_completed)

      instance.on_success_callback(entity)
    end
  end

  describe '#on_error_callback' do
    it 'updates entity sync_status to sync_failed' do
      expect(entity).to receive(:update!).with(sync_status: :sync_failed)

      instance.on_error_callback(entity)
    end
  end
end
