# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Bodacc::BuildResource, type: :interactor do
  let(:records_with_liquidation) do
    [
      {
        'id' => 'C202300123456',
        'familleavis_lib' => 'Procédure collective',
        'jugement' => '{"nature": "Liquidation judiciaire", "date": "2023-06-15"}',
        'listepersonnes' => '{"personne": {"denomination": "TEST SARL"}}'
      }
    ]
  end

  let(:records_with_dirigeant_risque) do
    [
      {
        'id' => 'C202300789012',
        'familleavis_lib' => 'Modifications diverses',
        'jugement' => nil,
        'listepersonnes' => '{"personne": {"qualification": "faillite personnelle du dirigeant"}}'
      }
    ]
  end

  let(:records_without_exclusions) do
    [
      {
        'id' => 'C202300345678',
        'familleavis_lib' => 'Dépôts des comptes',
        'jugement' => nil,
        'listepersonnes' => '{"personne": {"denomination": "CLEAN COMPANY"}}'
      }
    ]
  end

  describe '.call' do
    context 'when records contain liquidation' do
      subject { described_class.call(records: records_with_liquidation) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'detects liquidation from familleavis_lib' do
        result = subject
        expect(result.bundled_data.context[:liquidation_detected]).to be true
      end

      it 'sets has_exclusions to true' do
        result = subject
        expect(result.bundled_data.context[:has_exclusions]).to be true
      end

      it 'includes liquidation in exclusions_summary' do
        result = subject
        expect(result.bundled_data.context[:exclusions_summary]).to include('Liquidation judiciaire détectée')
      end

      it 'creates bundled_data with resource attributes' do
        result = subject
        expect(result.bundled_data.data).to be_a(Resource)
        expect(result.bundled_data.data.liquidation_judiciaire).to eq({
          'radio_choice' => 'yes',
          'text' => 'Liquidation détectée par Bodacc'
        })
        expect(result.bundled_data.data.faillite_interdiction).to eq({
          'radio_choice' => 'no'
        })
      end
    end

    context 'when records contain liquidation in jugement JSON' do
      let(:records_with_jugement_liquidation) do
        [
          {
            'id' => 'C202300999999',
            'familleavis_lib' => 'Autres avis',
            'jugement' => '{"nature": "liquidation judiciaire prononcée", "tribunal": "Paris"}',
            'listepersonnes' => '{}'
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

      it 'detects dirigeant à risque from listepersonnes' do
        result = subject
        expect(result.bundled_data.context[:dirigeant_a_risque]).to be true
      end

      it 'sets has_exclusions to true' do
        result = subject
        expect(result.bundled_data.context[:has_exclusions]).to be true
      end

      it 'includes dirigeant risque in exclusions_summary' do
        result = subject
        expect(result.bundled_data.context[:exclusions_summary]).to include('Dirigeant à risque détecté')
      end
    end

    context 'when records contain both liquidation and dirigeant à risque' do
      let(:records_with_both) do
        [
          {
            'id' => 'C202300111111',
            'familleavis_lib' => 'Procédure collective',
            'jugement' => '{"nature": "liquidation"}',
            'listepersonnes' => '{"dirigeant": "interdiction de gérer prononcée"}'
          }
        ]
      end

      subject { described_class.call(records: records_with_both) }

      it 'detects both exclusions' do
        result = subject
        expect(result.bundled_data.context[:liquidation_detected]).to be true
        expect(result.bundled_data.context[:dirigeant_a_risque]).to be true
        expect(result.bundled_data.context[:has_exclusions]).to be true
        expect(result.bundled_data.data.liquidation_judiciaire).to eq({ 'radio_choice' => 'yes', 'text' => 'Liquidation détectée par Bodacc' })
        expect(result.bundled_data.data.faillite_interdiction).to eq({ 'radio_choice' => 'yes', 'text' => 'Dirigeant à risque détecté par Bodacc' })
      end

      it 'includes both in exclusions_summary' do
        result = subject
        summary = result.bundled_data.context[:exclusions_summary]
        expect(summary).to include('Liquidation judiciaire détectée')
        expect(summary).to include('Dirigeant à risque détecté')
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

      it 'sets has_exclusions to false' do
        result = subject
        expect(result.bundled_data.context[:has_exclusions]).to be false
      end

      it 'has empty exclusions_summary' do
        result = subject
        expect(result.bundled_data.context[:exclusions_summary]).to be_empty
      end
    end

    context 'when jugement contains invalid JSON' do
      let(:records_with_invalid_json) do
        [
          {
            'id' => 'C202300222222',
            'familleavis_lib' => 'Autres avis',
            'jugement' => 'invalid json{{{',
            'listepersonnes' => '{}'
          }
        ]
      end

      subject { described_class.call(records: records_with_invalid_json) }

      it 'handles invalid JSON gracefully' do
        expect { subject }.not_to raise_error
        result = subject
        expect(result.bundled_data.context[:liquidation_detected]).to be false
      end
    end

    context 'when listepersonnes contains invalid JSON' do
      let(:records_with_invalid_personnes_json) do
        [
          {
            'id' => 'C202300333333',
            'familleavis_lib' => 'Autres avis',
            'jugement' => nil,
            'listepersonnes' => 'invalid json}}}'
          }
        ]
      end

      subject { described_class.call(records: records_with_invalid_personnes_json) }

      it 'handles invalid JSON gracefully' do
        expect { subject }.not_to raise_error
        result = subject
        expect(result.bundled_data.context[:dirigeant_a_risque]).to be false
      end
    end

    context 'when records is empty' do
      subject { described_class.call(records: []) }

      it 'succeeds with no exclusions' do
        result = subject
        expect(result).to be_success
        expect(result.bundled_data.context[:has_exclusions]).to be false
        expect(result.bundled_data.context[:liquidation_detected]).to be false
        expect(result.bundled_data.context[:dirigeant_a_risque]).to be false
        expect(result.bundled_data.context[:exclusions_summary]).to be_empty
      end
    end
  end
end
