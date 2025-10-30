require 'rails_helper'

RSpec.describe SkippableStepCalculator do
  let(:public_market) { create(:public_market, :completed) }
  let(:market_application) { create(:market_application, public_market:) }
  let(:step_name) { 'motifs_exclusion_condamnations_penales' }

  describe '#call' do
    context 'when step is not an exclusion step' do
      let(:step_name) { 'some_other_step' }

      it 'returns false' do
        result = described_class.call(market_application, step_name)
        expect(result).to be false
      end
    end

    context 'when subject_to_prohibition is nil' do
      before { market_application.update(subject_to_prohibition: nil) }

      it 'returns false' do
        result = described_class.call(market_application, step_name)
        expect(result).to be false
      end
    end

    context 'when subject_to_prohibition is true' do
      before { market_application.update(subject_to_prohibition: true) }

      it 'returns false (all fields visible, do not skip)' do
        result = described_class.call(market_application, step_name)
        expect(result).to be false
      end
    end

    context 'when subject_to_prohibition is false' do
      before { market_application.update(subject_to_prohibition: false) }

      context 'and step has no responses' do
        before do
          allow_any_instance_of(MarketApplicationPresenter)
            .to receive(:responses_grouped_by_subcategory)
            .and_return({ step_name => nil })
        end

        it 'returns false (show step if no data)' do
          result = described_class.call(market_application, step_name)
          expect(result).to be false
        end
      end

      context 'and step has visible fields (radio_with_justification_required)' do
        let(:response) { double('Response', type: 'MarketAttributeResponse::RadioWithJustificationRequired', auto?: false) }

        before do
          allow_any_instance_of(MarketApplicationPresenter)
            .to receive(:responses_grouped_by_subcategory)
            .and_return({ step_name => [response] })
        end

        it 'returns false (do not skip)' do
          result = described_class.call(market_application, step_name)
          expect(result).to be false
        end
      end

      context 'and step has ONLY hidden fields' do
        let(:response) { double('Response', type: 'MarketAttributeResponse::RadioWithFileAndText', auto?: false) }

        before do
          allow_any_instance_of(MarketApplicationPresenter)
            .to receive(:responses_grouped_by_subcategory)
            .and_return({ step_name => [response] })
        end

        it 'returns true (skip this step)' do
          result = described_class.call(market_application, step_name)
          expect(result).to be true
        end
      end

      context 'and step has auto-filled fields' do
        let(:response) { double('Response', type: 'MarketAttributeResponse::RadioWithJustificationRequired', auto?: true) }

        before do
          allow_any_instance_of(MarketApplicationPresenter)
            .to receive(:responses_grouped_by_subcategory)
            .and_return({ step_name => [response] })
        end

        it 'returns false (auto fields are always visible, so do not skip)' do
          result = described_class.call(market_application, step_name)
          expect(result).to be false
        end
      end

      context 'and step has mixed fields' do
        let(:hidden_response) { double('Response', type: 'MarketAttributeResponse::RadioWithFileAndText', auto?: false) }
        let(:visible_response) { double('Response', type: 'MarketAttributeResponse::RadioWithJustificationRequired', auto?: false) }

        before do
          allow_any_instance_of(MarketApplicationPresenter)
            .to receive(:responses_grouped_by_subcategory)
            .and_return({ step_name => [hidden_response, visible_response] })
        end

        it 'returns false (has at least one visible field)' do
          result = described_class.call(market_application, step_name)
          expect(result).to be false
        end
      end
    end
  end
end
