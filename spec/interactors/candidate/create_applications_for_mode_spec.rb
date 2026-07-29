# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::CreateApplicationsForMode, type: :interactor do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:siret) { '73282932000074' }
  let!(:market_application) { create(:market_application, public_market:, siret:) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe '.call' do
    context 'when application_mode is not a recognized value' do
      subject { described_class.call(market_application:, application_mode: 'invalid_garbage') }

      it 'fails instead of silently leaving the mode unset' do
        expect(subject).to be_failure
      end

      it 'does not set application_mode on the market_application' do
        subject
        expect(market_application.reload.application_mode).to be_nil
      end

      it 'does not create a second market_application' do
        expect { subject }.not_to change(MarketApplication, :count)
      end

      it 'does not create a grouping' do
        expect { subject }.not_to change(Grouping, :count)
      end
    end

    context 'when application_mode is solo' do
      subject { described_class.call(market_application:, application_mode: 'solo') }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'sets the mode on the existing application without creating a new one' do
        expect { subject }.not_to change(MarketApplication, :count)
        expect(subject.market_application).to eq(market_application)
        expect(subject.market_application).to be_solo
      end

      it 'does not create a grouping' do
        expect { subject }.not_to change(Grouping, :count)
      end
    end

    context 'when application_mode is groupement' do
      subject { described_class.call(market_application:, application_mode: 'groupement') }

      it 'sets the mode on the existing application without creating a new one' do
        expect { subject }.not_to change(MarketApplication, :count)
        expect(subject.market_application).to eq(market_application)
        expect(subject.market_application).to be_groupement
      end

      it 'creates a grouping with the application as mandataire' do
        expect { subject }.to change(Grouping, :count).by(1)

        grouping = Grouping.last
        expect(grouping.mandataire_market_application).to eq(market_application)
        expect(grouping.public_market).to eq(public_market)
      end

      it 'creates a mandataire grouping_member' do
        subject

        member = Grouping.last.grouping_members.sole
        expect(member).to be_mandataire
        expect(member.siret).to eq(siret)
        expect(member.market_application).to eq(market_application)
      end
    end

    context 'when application_mode is mixte' do
      subject { described_class.call(market_application:, application_mode: 'mixte') }

      it 'creates one additional application (the groupement counterpart)' do
        expect { subject }.to change(MarketApplication, :count).by(1)
      end

      it 'turns the existing application into the solo counterpart' do
        result = subject
        expect(result.solo_market_application).to eq(market_application)
        expect(result.solo_market_application).to be_solo
      end

      it 'creates a distinct groupement application' do
        result = subject
        expect(result.groupement_market_application).to be_groupement
        expect(result.groupement_market_application).not_to eq(market_application)
      end

      it 'creates a grouping for the groupement application only' do
        result = subject

        expect(Grouping.count).to eq(1)
        expect(Grouping.last.mandataire_market_application).to eq(result.groupement_market_application)
      end
    end

    context 'when the SIRET is already mandataire of a grouping on this market' do
      before do
        other_application = create(:market_application, public_market:, siret:, application_mode: :groupement)
        create(:grouping, public_market:, mandataire_market_application: other_application)
      end

      it 'fails for groupement mode' do
        result = described_class.call(market_application:, application_mode: 'groupement')
        expect(result).to be_failure
      end

      it 'fails for mixte mode without creating a second application' do
        expect do
          described_class.call(market_application:, application_mode: 'mixte')
        end.not_to change(MarketApplication, :count)
      end

      it 'succeeds for solo mode' do
        result = described_class.call(market_application:, application_mode: 'solo')
        expect(result).to be_success
      end
    end

    context 'when a concurrent request creates the competing grouping between the upfront check and the insert' do
      subject { described_class.call(market_application:, application_mode: 'groupement') }

      before do
        allow(Candidate::ValidateApplicationMode).to receive(:call).and_return(Interactor::Context.new)
        allow(Grouping).to receive(:create).and_wrap_original do |original, attributes|
          other_application = create(:market_application, public_market:, siret:, application_mode: :groupement)
          create(:grouping, public_market:, mandataire_market_application: other_application)

          original.call(attributes)
        end
      end

      it 'fails with the functional already-mandataire message rather than a raw validation error' do
        expect(subject).to be_failure
        expect(subject.errors[:application_mode]).to eq([I18n.t('candidate.validations.already_mandataire')])
      end
    end

    context 'when the mandataire uniqueness Ruby validation is bypassed and only the database constraint remains (race condition safety net)' do
      subject { described_class.call(market_application:, application_mode: 'groupement') }

      before do
        allow(Candidate::ValidateApplicationMode).to receive(:call).and_return(Interactor::Context.new)
        other_application = create(:market_application, public_market:, siret:, application_mode: :groupement)
        create(:grouping, public_market:, mandataire_market_application: other_application)
        allow(Grouping).to receive(:create) do |attributes|
          Grouping.new(attributes).tap do |g|
            g.mandataire_siret = attributes[:mandataire_market_application].siret
            g.save(validate: false)
          end
        end
      end

      it 'fails instead of raising an unhandled database error' do
        expect(subject).to be_failure
        expect(subject.errors[:application_mode]).to be_present
      end

      it 'does not leave a duplicate mandataire grouping behind' do
        subject
        expect(Grouping.where(public_market:).count).to eq(1)
      end
    end

    context 'when mixte mode hits the race condition safety net on the groupement counterpart' do
      subject { described_class.call(market_application:, application_mode: 'mixte') }

      before do
        allow(Candidate::ValidateApplicationMode).to receive(:call).and_return(Interactor::Context.new)
        other_application = create(:market_application, public_market:, siret:, application_mode: :groupement)
        create(:grouping, public_market:, mandataire_market_application: other_application)
        allow(Grouping).to receive(:create) do |attributes|
          Grouping.new(attributes).tap do |g|
            g.mandataire_siret = attributes[:mandataire_market_application].siret
            g.save(validate: false)
          end
        end
      end

      it 'fails instead of raising an unhandled database error' do
        expect(subject).to be_failure
        expect(subject.errors[:application_mode]).to be_present
      end

      it 'rolls back the groupement counterpart application created earlier in the transaction' do
        expect { subject }.not_to change(MarketApplication, :count)
      end

      it 'leaves the original application without a mode' do
        subject
        expect(market_application.reload.application_mode).to be_nil
      end

      it 'does not leave a duplicate mandataire grouping behind' do
        subject
        expect(Grouping.where(public_market:).count).to eq(1)
      end
    end
  end
end
