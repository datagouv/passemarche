# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditorSyncService do
  describe '.call' do
    context 'when doorkeeper application does not exist' do
      let(:editor) { build(:editor, name: 'Test Editor', client_id: 'test_client', client_secret: 'test_secret') }

      it 'creates a new doorkeeper application' do
        expect do
          described_class.call(editor)
        end.to change(CustomDoorkeeperApplication, :count).by(1)
      end

      it 'creates doorkeeper application with correct attributes' do
        result = described_class.call(editor)

        expect(result).to be_a(CustomDoorkeeperApplication)
        expect(result.name).to eq('Test Editor')
        expect(result.uid).to eq('test_client')
        expect(result.secret).to eq('test_secret')
        expect(result.scopes.to_s).to eq('api_access api_read api_write')
        expect(result.redirect_uri).to eq('')
      end
    end

    context 'when doorkeeper application already exists' do
      let!(:existing_app) do
        CustomDoorkeeperApplication.create!(
          name: 'Old Name',
          uid: 'existing_client_id',
          secret: 'old_secret',
          redirect_uri: '',
          scopes: 'api_access'
        )
      end
      let(:editor) { build(:editor, name: 'Test Editor', client_id: 'existing_client_id', client_secret: 'test_secret') }

      it 'returns existing doorkeeper application without creating new one' do
        expect do
          result = described_class.call(editor)
          expect(result).to eq(existing_app)
        end.not_to change(CustomDoorkeeperApplication, :count)
      end

      it 'does not modify existing application' do
        described_class.call(editor)

        existing_app.reload
        expect(existing_app.name).to eq('Old Name')
        expect(existing_app.secret).to eq('old_secret')
        expect(existing_app.scopes.to_s).to eq('api_access')
      end
    end
  end
end
