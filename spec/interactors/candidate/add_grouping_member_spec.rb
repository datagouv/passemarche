# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::AddGroupingMember, type: :interactor do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:mandataire_application) do
    create(:market_application, public_market:, siret: '73282932000074', application_mode: :groupement)
  end
  let(:grouping) do
    create(:grouping, public_market:, mandataire_market_application: mandataire_application, legal_type: :conjoint)
  end

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe '.call' do
    subject(:result) { described_class.call(grouping:, siret:, email:) }

    let(:siret) { '80245139600027' }
    let(:email) { 'contact@menuiseries-loire.fr' }

    context 'when the SIRET and email are valid and the SIRET is not already in the grouping' do
      before do
        allow(FetchRaisonSociale).to receive(:call).and_return(
          OpenStruct.new(success?: true, raison_sociale: 'MENUISERIES DE LOIRE SARL')
        )
      end

      it 'succeeds' do
        expect(result).to be_success
      end

      it 'creates a co_traitant grouping member' do
        expect { result }.to change { grouping.grouping_members.co_traitant.count }.by(1)
      end

      it 'stores the resolved company name' do
        member = result.grouping_member
        expect(member.company_name).to eq('MENUISERIES DE LOIRE SARL')
      end

      it 'does not send an invitation yet' do
        member = result.grouping_member
        expect(member.invitation_sent?).to be false
      end
    end

    context 'when the company name API call fails' do
      before do
        allow(FetchRaisonSociale).to receive(:call).and_return(
          OpenStruct.new(success?: false, raison_sociale: nil)
        )
      end

      it 'still succeeds and creates the member without a company name' do
        expect(result).to be_success
        expect(result.grouping_member.company_name).to be_nil
      end
    end

    context 'when the company name API call raises (network error, WebMock, ...)' do
      before do
        allow(FetchRaisonSociale).to receive(:call).and_raise(SocketError, 'connection failed')
        allow(Sentry).to receive(:capture_exception)
      end

      it 'still succeeds and creates the member without a company name' do
        expect(result).to be_success
        expect(result.grouping_member.company_name).to be_nil
      end

      it 'reports the exception to Sentry' do
        result
        expect(Sentry).to have_received(:capture_exception)
      end
    end

    context 'when the SIRET is blank' do
      let(:siret) { '' }

      it 'fails with a siret error' do
        expect(result).to be_failure
        expect(result.errors[:siret]).to be_present
      end

      it 'does not clear the email error slot' do
        expect(result.errors[:email]).to be_blank
      end
    end

    context 'when the SIRET is invalid' do
      before { allow(SiretValidator).to receive(:valid?).with(siret).and_return(false) }

      it 'fails with a siret error' do
        expect(result).to be_failure
        expect(result.errors[:siret]).to be_present
      end
    end

    context 'when the SIRET is the mandataire own SIRET' do
      let(:siret) { mandataire_application.siret }

      it 'fails with a siret error' do
        expect(result).to be_failure
        expect(result.errors[:siret]).to be_present
      end
    end

    context 'when the SIRET has already been added to the grouping' do
      before do
        allow(FetchRaisonSociale).to receive(:call).and_return(
          OpenStruct.new(success?: true, raison_sociale: 'MENUISERIES DE LOIRE SARL')
        )
        create(:grouping_member, :co_traitant, grouping:, siret:)
      end

      it 'fails with a siret error' do
        expect(result).to be_failure
        expect(result.errors[:siret]).to be_present
      end
    end

    context 'when the email is blank' do
      let(:email) { '' }

      it 'fails with an email error' do
        expect(result).to be_failure
        expect(result.errors[:email]).to be_present
      end

      it 'does not clear the siret error slot' do
        expect(result.errors[:siret]).to be_blank
      end
    end

    context 'when the email is invalid' do
      let(:email) { 'not-an-email' }

      it 'fails with an email error' do
        expect(result).to be_failure
        expect(result.errors[:email]).to be_present
      end
    end
  end
end
