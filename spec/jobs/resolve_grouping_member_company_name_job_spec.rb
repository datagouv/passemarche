# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ResolveGroupingMemberCompanyNameJob, type: :job do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:mandataire_application) do
    create(:market_application, public_market:, siret: '73282932000074', application_mode: :groupement)
  end
  let(:grouping) do
    create(:grouping, public_market:, mandataire_market_application: mandataire_application, legal_type: :conjoint)
  end
  let(:grouping_member) { create(:grouping_member, :co_traitant, grouping:, company_name: nil) }

  before { allow(SiretValidator).to receive(:valid?).and_return(true) }

  describe '#perform' do
    context 'when FetchRaisonSociale succeeds' do
      before do
        allow(FetchRaisonSociale).to receive(:call).and_return(
          OpenStruct.new(success?: true, raison_sociale: 'MENUISERIES DE LOIRE SARL')
        )
      end

      it 'calls FetchRaisonSociale with the member siret' do
        expect(FetchRaisonSociale).to receive(:call).with(siret: grouping_member.siret)
        described_class.perform_now(grouping_member.id)
      end

      it 'stores the resolved company name' do
        described_class.perform_now(grouping_member.id)
        expect(grouping_member.reload.company_name).to eq('MENUISERIES DE LOIRE SARL')
      end
    end

    context 'when FetchRaisonSociale fails' do
      before do
        allow(FetchRaisonSociale).to receive(:call).and_return(OpenStruct.new(success?: false, raison_sociale: nil))
      end

      it 'does not update company_name' do
        described_class.perform_now(grouping_member.id)
        expect(grouping_member.reload.company_name).to be_nil
      end
    end

    context 'when the grouping member already has a company_name' do
      let(:grouping_member) { create(:grouping_member, :co_traitant, grouping:, company_name: 'ATLANTIQUE BÂTIMENT SAS') }

      it 'does not call FetchRaisonSociale' do
        allow(FetchRaisonSociale).to receive(:call)
        described_class.perform_now(grouping_member.id)
        expect(FetchRaisonSociale).not_to have_received(:call)
      end
    end

    context 'when the grouping member does not exist' do
      it 'discards the job without raising' do
        expect { described_class.perform_now(-1) }.not_to raise_error
      end
    end

    context 'when FetchRaisonSociale raises (network error, WebMock, ...)' do
      before do
        allow(FetchRaisonSociale).to receive(:call).and_raise(SocketError, 'connection failed')
        allow(Sentry).to receive(:capture_exception)
      end

      it 'does not raise' do
        expect { described_class.perform_now(grouping_member.id) }.not_to raise_error
      end

      it 'reports the exception to Sentry' do
        described_class.perform_now(grouping_member.id)
        expect(Sentry).to have_received(:capture_exception)
      end

      it 'does not update company_name' do
        described_class.perform_now(grouping_member.id)
        expect(grouping_member.reload.company_name).to be_nil
      end
    end
  end
end
