# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Editor, 'webhook configuration', type: :model do
  let(:editor) { build(:editor) }

  describe 'validations' do
    describe 'URL validations' do
      context 'in development' do
        before { allow(Rails.env).to receive(:production?).and_return(false) }

        it 'accepts HTTP URLs' do
          editor.completion_webhook_url = 'http://example.com/webhook'
          editor.redirect_url = 'http://example.com/success'
          expect(editor).to be_valid
        end

        it 'accepts HTTPS URLs' do
          editor.completion_webhook_url = 'https://example.com/webhook'
          editor.redirect_url = 'https://example.com/success'
          expect(editor).to be_valid
        end
      end

      context 'in production' do
        before { allow(Rails.env).to receive(:production?).and_return(true) }

        it 'rejects HTTP URLs for webhook' do
          editor.completion_webhook_url = 'http://example.com/webhook'
          expect(editor).not_to be_valid
          expect(editor.errors[:completion_webhook_url]).to include('doit utiliser HTTPS en production')
        end

        it 'rejects HTTP URLs for redirect' do
          editor.redirect_url = 'http://example.com/success'
          expect(editor).not_to be_valid
          expect(editor.errors[:redirect_url]).to include('doit utiliser HTTPS en production')
        end

        it 'accepts HTTPS URLs' do
          editor.completion_webhook_url = 'https://example.com/webhook'
          editor.redirect_url = 'https://example.com/success'
          expect(editor).to be_valid
        end
      end

      it 'rejects invalid URLs' do
        editor.completion_webhook_url = 'not a url'
        expect(editor).not_to be_valid
        expect(editor.errors[:completion_webhook_url]).to include("n'est pas une URL valide")
      end

      it 'allows blank URLs' do
        editor.completion_webhook_url = nil
        editor.redirect_url = nil
        expect(editor).to be_valid
      end
    end
  end

  describe '#generate_webhook_secret!' do
    it 'generates a 64-character hex secret' do
      editor.generate_webhook_secret!
      expect(editor.webhook_secret).to be_present
      expect(editor.webhook_secret.length).to eq(64)
      expect(editor.webhook_secret).to match(/\A[a-f0-9]{64}\z/)
    end

    it 'generates different secrets each time' do
      editor.generate_webhook_secret!
      secret1 = editor.webhook_secret
      editor.generate_webhook_secret!
      secret2 = editor.webhook_secret
      expect(secret1).not_to eq(secret2)
    end
  end

  describe '#webhook_configured?' do
    it 'returns false when webhook URL is blank' do
      editor.completion_webhook_url = nil
      expect(editor.webhook_configured?).to be false
    end

    it 'returns true when webhook URL is present' do
      editor.completion_webhook_url = 'https://example.com/webhook'
      expect(editor.webhook_configured?).to be true
    end
  end

  describe '#webhook_signature' do
    let(:payload) { '{"event":"test"}' }

    context 'with webhook secret' do
      before { editor.webhook_secret = 'secret123' }

      it 'generates HMAC-SHA256 signature' do
        expected = OpenSSL::HMAC.hexdigest('SHA256', 'secret123', payload)
        expect(editor.webhook_signature(payload)).to eq(expected)
      end

      it 'generates different signatures for different payloads' do
        sig1 = editor.webhook_signature('payload1')
        sig2 = editor.webhook_signature('payload2')
        expect(sig1).not_to eq(sig2)
      end
    end

    context 'without webhook secret' do
      before { editor.webhook_secret = nil }

      it 'returns nil' do
        expect(editor.webhook_signature(payload)).to be_nil
      end
    end
  end

  describe 'encryption' do
    it 'encrypts webhook_secret' do
      editor.webhook_secret = 'test_secret'
      editor.save!

      # The raw database value should be encrypted
      raw_value = Editor.connection.select_value(
        "SELECT webhook_secret FROM editors WHERE id = #{editor.id}"
      )

      expect(raw_value).not_to eq('test_secret') if raw_value.present?

      # But accessing through the model should decrypt it
      reloaded = Editor.find(editor.id)
      expect(reloaded.webhook_secret).to eq('test_secret')
    end
  end

  describe 'scopes' do
    describe '.with_webhook_configured' do
      let!(:configured_editor) { create(:editor, completion_webhook_url: 'https://example.com/webhook') }
      let!(:unconfigured_editor) { create(:editor, completion_webhook_url: nil) }

      it 'returns only editors with webhook URL configured' do
        expect(Editor.with_webhook_configured).to include(configured_editor)
        expect(Editor.with_webhook_configured).not_to include(unconfigured_editor)
      end
    end
  end
end
