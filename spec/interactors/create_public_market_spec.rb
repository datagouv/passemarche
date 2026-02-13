# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreatePublicMarket, type: :interactor do
  let(:editor) { create(:editor) }
  let(:valid_params) do
    {
      name: 'Test Market',
      lot_name: 'Lot A',
      deadline: 1.month.from_now,
      siret: '13002526500013',
      market_type_codes: ['supplies']
    }
  end

  before do
    MarketType.find_or_create_by(code: 'supplies')
  end

  describe '.call' do
    context 'with valid parameters' do
      subject { described_class.call(editor:, params: valid_params) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates a public market' do
        expect { subject }.to change(PublicMarket, :count).by(1)
      end

      it 'returns the created market' do
        result = subject
        expect(result.public_market).to be_a(PublicMarket)
        expect(result.public_market.name).to eq('Test Market')
        expect(result.public_market.editor).to eq(editor)
      end
    end

    context 'with nil editor' do
      subject { described_class.call(editor: nil, params: valid_params) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'has editor error' do
        expect(subject.errors[:editor]).to include('Editor not found')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) { valid_params.merge(name: nil) }

      subject { described_class.call(editor:, params: invalid_params) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'has validation errors' do
        expect(subject.errors[:name]).to be_present
      end
    end

    context 'with missing SIRET' do
      let(:invalid_params) { valid_params.except(:siret) }

      subject { described_class.call(editor:, params: invalid_params) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'has SIRET validation error' do
        expect(subject.errors[:siret]).to be_present
      end
    end

    context 'with invalid SIRET format' do
      let(:invalid_params) { valid_params.merge(siret: '1300252650001') }

      subject { described_class.call(editor:, params: invalid_params) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'has SIRET validation error' do
        expect(subject.errors[:siret]).to include('Le numéro de SIRET saisi est invalide ou non reconnu')
      end
    end

    context 'with invalid SIRET checksum' do
      let(:invalid_params) { valid_params.merge(siret: '13002526500014') }

      subject { described_class.call(editor:, params: invalid_params) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'has SIRET validation error' do
        expect(subject.errors[:siret]).to include('Le numéro de SIRET saisi est invalide ou non reconnu')
      end
    end

    context 'with valid SIRET' do
      subject { described_class.call(editor:, params: valid_params) }

      it 'stores the SIRET correctly' do
        expect(subject.public_market.siret).to eq('13002526500013')
      end
    end
  end
end
