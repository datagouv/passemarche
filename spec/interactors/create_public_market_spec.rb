# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreatePublicMarket, type: :interactor do
  let(:editor) { create(:editor) }
  let(:valid_params) do
    {
      name: 'Test Market',
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

      it 'enqueues FetchPublicMarketBuyerNameJob' do
        expect { subject }.to have_enqueued_job(FetchPublicMarketBuyerNameJob)
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
        expect(subject.errors[:siret]).to be_present
      end
    end

    context 'with invalid SIRET checksum' do
      let(:invalid_params) { valid_params.merge(siret: '13002526500014') }

      subject { described_class.call(editor:, params: invalid_params) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'has SIRET validation error' do
        expect(subject.errors[:siret]).to be_present
      end
    end

    context 'with valid SIRET' do
      subject { described_class.call(editor:, params: valid_params) }

      it 'stores the SIRET correctly' do
        expect(subject.public_market.siret).to eq('13002526500013')
      end
    end

    context 'with multiple lots' do
      let(:params_with_lots) do
        valid_params.merge(lots: [{ name: 'Lot 1' }, { name: 'Lot 2' }])
      end

      subject { described_class.call(editor:, params: params_with_lots) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates the lots' do
        expect { subject }.to change(Lot, :count).by(2)
      end

      it 'associates lots with the market' do
        result = subject
        expect(result.public_market.lots.map(&:name)).to contain_exactly('Lot 1', 'Lot 2')
      end

      it 'assigns positions sequentially' do
        result = subject
        expect(result.public_market.lots.ordered.map(&:position)).to eq([1, 2])
      end

      it 'assigns platform_market_type from global market type when no per-lot type' do
        result = subject
        supplies = MarketType.find_by(code: 'supplies')
        expect(result.public_market.lots.map(&:platform_market_type)).to all(eq(supplies))
      end
    end

    context 'with lots having a per-lot type' do
      before { MarketType.find_or_create_by(code: 'works') }

      let(:params_with_per_lot_type) do
        valid_params.merge(lots: [
          { name: 'Lot 1', lot_type_code: 'supplies' },
          { name: 'Lot 2', lot_type_code: 'works' }
        ])
      end

      subject { described_class.call(editor:, params: params_with_per_lot_type) }

      it 'assigns each lot its own platform_market_type' do
        result = subject
        types = result.public_market.lots.ordered.map { |l| l.platform_market_type.code }
        expect(types).to eq(%w[supplies works])
      end
    end

    context 'with lots having cpv_code' do
      let(:params_with_cpv) do
        valid_params.merge(lots: [{ name: 'Lot 1', cpv_code: '45000000-7' }, { name: 'Lot 2', cpv_code: nil }])
      end

      subject { described_class.call(editor:, params: params_with_cpv) }

      it 'persists the cpv_code' do
        result = subject
        expect(result.public_market.lots.ordered.map(&:cpv_code)).to eq(['45000000-7', nil])
      end
    end

    context 'with lot_limit exceeding the number of lots' do
      let(:params_with_limit) do
        valid_params.merge(
          lots: [{ name: 'Lot 1' }, { name: 'Lot 2' }],
          lot_limit: 5
        )
      end

      subject { described_class.call(editor:, params: params_with_limit) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'has a lot_limit validation error' do
        expect(subject.errors[:lot_limit]).to be_present
      end

      it 'does not create the market' do
        expect { subject }.not_to change(PublicMarket, :count)
      end
    end

    context 'without lots' do
      subject { described_class.call(editor:, params: valid_params) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates no lots' do
        expect { subject }.not_to change(Lot, :count)
      end
    end
  end
end
