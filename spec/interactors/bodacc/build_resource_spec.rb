# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bodacc::BuildResource, type: :interactor do
  let(:records_with_liquidation) do
    [
      {
        'id' => 'C202300123456',
        'publicationavis' => 'A',
        'jugement' => '{"nature": "Liquidation judiciaire", "codeNature": "LJ", "date": "2023-06-15"}'
      }
    ]
  end

  let(:records_with_dirigeant_risque) do
    [
      {
        'id' => 'C202300789012',
        'publicationavis' => 'A',
        'jugement' => '{"nature": "Faillite personnelle", "codeNature": "FP"}'
      }
    ]
  end

  let(:records_without_exclusions) do
    [
      {
        'id' => 'C202300345678',
        'publicationavis' => 'A',
        'jugement' => '{"nature": "Clôture", "codeNature": "CL"}'
      }
    ]
  end

  describe '.call' do
    context 'when records contain liquidation' do
      subject { described_class.call(records: records_with_liquidation) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'detects liquidation from publicationavis and jugement' do
        result = subject
        expect(result.bundled_data.context[:liquidation_detected]).to be true
      end

      it 'creates bundled_data with resource attributes' do
        result = subject
        expect(result.bundled_data.data).to be_a(Resource)
        expect(result.bundled_data.data.liquidation_judiciaire['radio_choice']).to eq('yes')
        expect(result.bundled_data.data.faillite_interdiction['radio_choice']).to eq('no')
      end
    end

    context 'when records contain liquidation in jugement JSON' do
      let(:records_with_jugement_liquidation) do
        [
          {
            'id' => 'C202300999999',
            'publicationavis' => 'A',
            'jugement' => '{"nature": "liquidation judiciaire prononcée", "tribunal": "Paris"}'
          }
        ]
      end

      subject { described_class.call(records: records_with_jugement_liquidation) }

      it 'detects liquidation from jugement nature' do
        result = subject
        expect(result.bundled_data.context[:liquidation_detected]).to be true
      end
    end

    context 'when records contain dirigeant à risque' do
      subject { described_class.call(records: records_with_dirigeant_risque) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'detects dirigeant à risque from publicationavis and jugement' do
        result = subject
        expect(result.bundled_data.context[:dirigeant_a_risque]).to be true
      end
    end

    context 'when records contain both liquidation and dirigeant à risque' do
      let(:records_with_both) do
        [
          {
            'id' => 'C202300111111',
            'publicationavis' => 'A',
            'jugement' => '{"nature": "liquidation", "codeNature": "LJS"}'
          },
          {
            'id' => 'C202300111112',
            'publicationavis' => 'A',
            'jugement' => '{"nature": "interdiction de gérer", "codeNature": "IG"}'
          }
        ]
      end

      subject { described_class.call(records: records_with_both) }

      it 'detects both liquidation and dirigeant à risque' do
        result = subject
        expect(result.bundled_data.context[:liquidation_detected]).to be true
        expect(result.bundled_data.context[:dirigeant_a_risque]).to be true
        expect(result.bundled_data.data.liquidation_judiciaire['radio_choice']).to eq('yes')
        expect(result.bundled_data.data.faillite_interdiction['radio_choice']).to eq('yes')
      end
    end

    context 'when records contain no exclusions' do
      subject { described_class.call(records: records_without_exclusions) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'detects no liquidation' do
        result = subject
        expect(result.bundled_data.context[:liquidation_detected]).to be false
        expect(result.bundled_data.data.liquidation_judiciaire).to eq({ 'radio_choice' => 'no' })
      end

      it 'detects no dirigeant à risque' do
        result = subject
        expect(result.bundled_data.context[:dirigeant_a_risque]).to be false
        expect(result.bundled_data.data.faillite_interdiction).to eq({ 'radio_choice' => 'no' })
      end
    end

    context 'when jugement contains invalid JSON' do
      let(:records_with_invalid_json) do
        [
          {
            'id' => 'C202300222222',
            'publicationavis' => 'A',
            'jugement' => 'invalid json{{{'
          }
        ]
      end

      subject { described_class.call(records: records_with_invalid_json) }

      it 'handles invalid JSON gracefully' do
        expect { subject }.not_to raise_error
        result = subject
        expect(result.bundled_data.context[:liquidation_detected]).to be false
        expect(result.bundled_data.context[:dirigeant_a_risque]).to be false
      end
    end

    context 'when records is empty' do
      subject { described_class.call(records: []) }

      it 'succeeds with no exclusions' do
        result = subject
        expect(result).to be_success
        expect(result.bundled_data.context[:liquidation_detected]).to be false
        expect(result.bundled_data.context[:dirigeant_a_risque]).to be false
        expect(result.bundled_data.data.liquidation_judiciaire['radio_choice']).to eq('no')
        expect(result.bundled_data.data.faillite_interdiction['radio_choice']).to eq('no')
      end
    end
  end
end
