# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditorUpdateSyncService do
  let(:editor) { create(:editor, name: 'Test Editor', client_id: 'test_client', client_secret: 'test_secret') }

  describe '.call' do
    context 'when doorkeeper application does not exist' do
      it 'creates a new doorkeeper application' do
        expect {
          described_class.call(editor)
        }.to change(CustomDoorkeeperApplication, :count).by(1)
      end

      it 'creates doorkeeper application with correct attributes' do
        result = described_class.call(editor)

        expect(result).to be_a(CustomDoorkeeperApplication)
        expect(result.name).to eq('Test Editor')
        expect(result.uid).to eq('test_client')
        expect(result.secret).to eq('test_secret')
        expect(result.scopes.to_s).to eq('api_access api_read api_write')
      end
    end

    context 'when doorkeeper application already exists' do
      let!(:existing_app) do
        CustomDoorkeeperApplication.create!(
          name: 'Old Name',
          uid: editor.client_id,
          secret: 'old_secret',
          redirect_uri: '',
          scopes: 'api_access'
        )
      end

      before do
        editor.update!(name: 'Updated Editor', client_secret: 'updated_secret')
      end

      it 'updates existing doorkeeper application' do
        result = described_class.call(editor)

        expect(result).to be_a(CustomDoorkeeperApplication)
        expect(result.id).to eq(existing_app.id)
        expect(result.name).to eq('Updated Editor')
        expect(result.secret).to eq('updated_secret')
        expect(result.scopes.to_s).to eq('api_access api_read api_write')
      end

      it 'does not create new application' do
        expect {
          described_class.call(editor)
        }.not_to change(CustomDoorkeeperApplication, :count)
      end
    end
  end
end
