# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::CompleteGroupingMember, type: :interactor do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  describe '.call' do
    subject(:result) { described_class.call(market_application:) }

    context 'when the application belongs to a grouping member and is not completed yet' do
      let(:grouping) { create(:grouping, public_market:) }
      let(:market_application) { grouping.mandataire_market_application }

      it 'succeeds' do
        expect(result).to be_success
      end

      it 'marks the market_application as completed' do
        expect { result }.to change { market_application.reload.completed? }.from(false).to(true)
      end

      it 'marks the grouping_member as completed' do
        expect { result }.to change { grouping.mandataire_grouping_member.reload.status_completed? }.from(false).to(true)
      end

      it 'does not generate any attestation, PDF or webhook' do
        expect(GenerateAttestationPdf).not_to receive(:call)
        expect(QueueMarketApplicationWebhook).not_to receive(:call)

        result
      end
    end

    context 'when the application belongs to a co_traitant' do
      let(:grouping) { create(:grouping, public_market:) }
      let(:market_application) do
        create(:market_application, public_market:, siret: '80245139600021', application_mode: :groupement)
      end

      before do
        grouping.mandataire_market_application.update!(user: create(:user))
        create(:grouping_member, :co_traitant, grouping:, siret: market_application.siret, market_application:)
      end

      it 'notifies the mandataire' do
        expect { result }.to have_enqueued_mail(GroupingMemberCompletionMailer, :completed)
      end

      context 'when the co_traitant transmits again after editing its application' do
        before do
          market_application.complete!
          market_application.grouping_member.mark_completed!
          market_application.grouping_member.mark_in_progress!
        end

        it 'marks the grouping_member as completed again' do
          expect { result }.to change { market_application.grouping_member.reload.status_completed? }.from(false).to(true)
        end

        it 'succeeds without changing the transmission date' do
          expect { result }.not_to(change { market_application.reload.completed_at })
          expect(result).to be_success
        end

        it 'notifies the mandataire of the modification' do
          expect { result }.to have_enqueued_mail(GroupingMemberCompletionMailer, :modified)
        end

        it 'refuses to transmit again an application that is no longer valid' do
          allow(market_application).to receive(:valid?).and_return(false)

          expect(result).to be_failure
          expect(market_application.grouping_member.reload).to be_status_in_progress
        end
      end
    end

    context 'when the application is not linked to any grouping member (solo)' do
      let(:market_application) { create(:market_application, public_market:, application_mode: :solo) }

      it 'succeeds and only marks the application as completed' do
        expect(result).to be_success
        expect(market_application.reload).to be_completed
      end
    end

    context 'when the mandataire transmits again after editing its application' do
      let(:grouping) { create(:grouping, public_market:) }
      let(:market_application) { grouping.mandataire_market_application }

      before do
        market_application.complete!
        grouping.mandataire_grouping_member.mark_in_progress!
      end

      it 'marks the grouping_member as completed again without changing the transmission date' do
        expect { result }.not_to(change { market_application.reload.completed_at })
        expect(result).to be_success
        expect(grouping.mandataire_grouping_member.reload).to be_status_completed
      end

      it 'does not send any notification' do
        expect { result }.not_to have_enqueued_mail(GroupingMemberCompletionMailer)
      end
    end

    context 'when the grouping has been submitted meanwhile' do
      let(:grouping) { create(:grouping, public_market:) }
      let(:market_application) do
        create(:market_application, public_market:, siret: '80245139600021', application_mode: :groupement)
      end

      before do
        grouping.mandataire_market_application.update!(user: create(:user))
        create(:grouping_member, :co_traitant, grouping:, siret: market_application.siret, market_application:)
        grouping.update!(submitted_at: Time.current, submission_mode: :partial)
      end

      it 'refuses the transmission' do
        expect(result).to be_failure
        expect(result.message).to eq(I18n.t('candidate.market_applications.grouping_locked_error'))
        expect(market_application.reload).not_to be_completed
        expect(market_application.grouping_member.reload).not_to be_status_completed
      end

      it 'does not notify the mandataire' do
        expect { result }.not_to have_enqueued_mail(GroupingMemberCompletionMailer)
      end
    end
  end
end
