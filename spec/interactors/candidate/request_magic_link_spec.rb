# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::RequestMagicLink, type: :interactor do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:, siret: '73282932000074') }
  let(:valid_email) { 'candidat@example.com' }
  let(:valid_siret) { market_application.siret }
  let(:host) { 'localhost:3000' }
  let(:protocol) { 'http://' }

  before do
    allow(SiretValidator).to receive(:valid?).and_call_original
    allow(SiretValidator).to receive(:valid?).with(valid_siret).and_return(true)
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.deliveries.clear
  end

  describe '.call' do
    context 'when email is invalid' do
      it 'fails' do
        result = described_class.call(email: 'not-an-email', siret: valid_siret, host:, protocol:)

        expect(result).to be_failure
        expect(result.errors[:email]).to be_present
      end

      it 'does not send an email' do
        described_class.call(email: 'not-an-email', siret: valid_siret, host:, protocol:)

        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context 'when SIRET is invalid (Luhn)' do
      before { allow(SiretValidator).to receive(:valid?).with('12345678901234').and_return(false) }

      it 'fails' do
        result = described_class.call(email: valid_email, siret: '12345678901234', host:, protocol:)

        expect(result).to be_failure
        expect(result.errors[:siret]).to be_present
      end

      it 'does not send an email' do
        described_class.call(email: valid_email, siret: '12345678901234', host:, protocol:)

        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context 'when no market application found for SIRET' do
      it 'fails' do
        market_application.destroy
        result = described_class.call(email: valid_email, siret: valid_siret, host:, protocol:)

        expect(result).to be_failure
        expect(result.errors[:siret]).to be_present
      end
    end

    context 'when market application already has a user and email does not match' do
      before { market_application.update!(user: create(:user, email: 'other@example.com')) }

      it 'fails' do
        result = described_class.call(email: valid_email, siret: valid_siret, host:, protocol:)

        expect(result).to be_failure
        expect(result.errors[:email]).to be_present
      end

      it 'does not send an email' do
        described_class.call(email: valid_email, siret: valid_siret, host:, protocol:)

        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context 'when reconnecting with matching SIRET and email' do
      let(:existing_user) { create(:user, email: valid_email) }

      before { market_application.update!(user: existing_user) }

      it 'succeeds' do
        result = described_class.call(email: valid_email, siret: valid_siret, host:, protocol:)

        expect(result).to be_success
      end

      it 'marks context as reconnection' do
        result = described_class.call(email: valid_email, siret: valid_siret, host:, protocol:)

        expect(result.reconnection).to be true
      end

      it 'sends the magic link email' do
        expect do
          described_class.call(email: valid_email, siret: valid_siret, host:, protocol:)
        end.to have_enqueued_mail(AuthMailer, :magic_link)
      end
    end

    context 'when all inputs are valid' do
      it 'succeeds' do
        result = described_class.call(email: valid_email, siret: valid_siret, host:, protocol:)

        expect(result).to be_success
      end

      it 'creates user if not existing' do
        expect do
          described_class.call(email: valid_email, siret: valid_siret, host:, protocol:)
        end.to change(User, :count).by(1)
      end

      it 'reuses existing user' do
        create(:user, email: valid_email)

        expect do
          described_class.call(email: valid_email, siret: valid_siret, host:, protocol:)
        end.not_to change(User, :count)
      end

      it 'sends the magic link email' do
        expect do
          described_class.call(email: valid_email, siret: valid_siret, host:, protocol:)
        end.to have_enqueued_mail(AuthMailer, :magic_link)
      end

      it 'updates authentication_token_sent_at' do
        freeze_time do
          described_class.call(email: valid_email, siret: valid_siret, host:, protocol:)

          user = User.find_by(email: valid_email)
          expect(user.authentication_token_sent_at).to eq(Time.current)
        end
      end

      it 'invalidates previous token on resend' do
        described_class.call(email: valid_email, siret: valid_siret, host:, protocol:)
        user = User.find_by(email: valid_email)
        first_sent_at = user.authentication_token_sent_at

        travel 1.minute do
          described_class.call(email: valid_email, siret: valid_siret, host:, protocol:)
          expect(user.reload.authentication_token_sent_at).to be > first_sent_at
        end
      end
    end
  end
end
