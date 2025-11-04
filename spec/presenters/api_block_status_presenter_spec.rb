# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiBlockStatusPresenter do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:, siret: '12345678901234') }
  let(:presenter) { ApiBlockStatusPresenter.new(market_application) }

  before do
    allow(SiretValidationService).to receive(:call).and_return(true)
  end

  describe '#blocks' do
    it 'returns all configured blocks' do
      blocks = presenter.blocks

      expect(blocks.size).to eq(3)
      expect(blocks.first.name).to eq('Identité de l\'entreprise')
      expect(blocks.second.name).to eq('Capacités économiques et financières')
      expect(blocks.last.name).to eq('Capacités techniques et professionnelles')
    end

    it 'returns blocks with correct APIs' do
      identity_block = presenter.blocks.first
      economic_block = presenter.blocks.second
      technical_block = presenter.blocks.last

      expect(identity_block.apis).to contain_exactly('insee', 'rne')
      expect(economic_block.apis).to contain_exactly('attestations_fiscales', 'probtp')
      expect(technical_block.apis).to contain_exactly('qualibat')
    end
  end

  describe '#all_blocks_done?' do
    it 'returns true when all APIs are completed' do
      market_application.update(api_fetch_status: {
        'insee' => { 'status' => 'completed' },
        'rne' => { 'status' => 'completed' },
        'attestations_fiscales' => { 'status' => 'completed' },
        'probtp' => { 'status' => 'completed' },
        'qualibat' => { 'status' => 'completed' }
      })

      expect(presenter.all_blocks_done?).to be true
    end

    it 'returns true when all APIs are completed or failed' do
      market_application.update(api_fetch_status: {
        'insee' => { 'status' => 'completed' },
        'rne' => { 'status' => 'failed' },
        'attestations_fiscales' => { 'status' => 'completed' },
        'probtp' => { 'status' => 'completed' },
        'qualibat' => { 'status' => 'failed' }
      })

      expect(presenter.all_blocks_done?).to be true
    end

    it 'returns false when at least one API is processing' do
      market_application.update(api_fetch_status: {
        'insee' => { 'status' => 'completed' },
        'rne' => { 'status' => 'processing' },
        'attestations_fiscales' => { 'status' => 'completed' },
        'probtp' => { 'status' => 'completed' }
      })

      expect(presenter.all_blocks_done?).to be false
    end

    it 'returns false when at least one API is pending' do
      market_application.update(api_fetch_status: {
        'insee' => { 'status' => 'completed' },
        'rne' => { 'status' => 'pending' },
        'attestations_fiscales' => { 'status' => 'completed' },
        'probtp' => { 'status' => 'completed' }
      })

      expect(presenter.all_blocks_done?).to be false
    end
  end

  describe '#current_block' do
    it 'returns the block that is currently loading' do
      market_application.update(api_fetch_status: {
        'insee' => { 'status' => 'completed' },
        'rne' => { 'status' => 'completed' },
        'attestations_fiscales' => { 'status' => 'processing' },
        'probtp' => { 'status' => 'pending' }
      })

      current = presenter.current_block

      expect(current).not_to be_nil
      expect(current.name).to eq('Capacités économiques et financières')
    end

    it 'returns nil when all blocks are done' do
      market_application.update(api_fetch_status: {
        'insee' => { 'status' => 'completed' },
        'rne' => { 'status' => 'completed' },
        'attestations_fiscales' => { 'status' => 'completed' },
        'probtp' => { 'status' => 'completed' },
        'qualibat' => { 'status' => 'completed' }
      })

      expect(presenter.current_block).to be_nil
    end
  end

  describe '#completed_blocks_count' do
    it 'returns the number of completed blocks' do
      market_application.update(api_fetch_status: {
        'insee' => { 'status' => 'completed' },
        'rne' => { 'status' => 'completed' },
        'attestations_fiscales' => { 'status' => 'processing' },
        'probtp' => { 'status' => 'pending' },
        'qualibat' => { 'status' => 'pending' }
      })

      expect(presenter.completed_blocks_count).to eq(1)
    end
  end

  describe '#failed_blocks_count' do
    it 'returns the number of failed blocks' do
      market_application.update(api_fetch_status: {
        'insee' => { 'status' => 'failed' },
        'rne' => { 'status' => 'failed' },
        'attestations_fiscales' => { 'status' => 'completed' },
        'probtp' => { 'status' => 'completed' },
        'qualibat' => { 'status' => 'pending' }
      })

      expect(presenter.failed_blocks_count).to eq(1)
    end
  end

  describe '#overall_status_message' do
    it 'returns success message when all blocks completed successfully' do
      market_application.update(api_fetch_status: {
        'insee' => { 'status' => 'completed' },
        'rne' => { 'status' => 'completed' },
        'attestations_fiscales' => { 'status' => 'completed' },
        'probtp' => { 'status' => 'completed' },
        'qualibat' => { 'status' => 'completed' }
      })

      expect(presenter.overall_status_message).to eq('L\'ensemble des informations et documents ont été récupérés')
    end

    it 'returns partial failure message when some blocks failed' do
      market_application.update(api_fetch_status: {
        'insee' => { 'status' => 'completed' },
        'rne' => { 'status' => 'completed' },
        'attestations_fiscales' => { 'status' => 'failed' },
        'probtp' => { 'status' => 'failed' },
        'qualibat' => { 'status' => 'completed' }
      })

      expect(presenter.overall_status_message).to include('bloc(s) n\'ont pas pu être récupérés')
    end

    it 'returns in progress message when not all done' do
      market_application.update(api_fetch_status: {
        'insee' => { 'status' => 'processing' },
        'rne' => { 'status' => 'pending' },
        'attestations_fiscales' => { 'status' => 'pending' },
        'probtp' => { 'status' => 'pending' }
      })

      expect(presenter.overall_status_message).to eq('Récupération en cours, veuillez patienter...')
    end
  end

  describe ApiBlockStatusPresenter::ApiBlock do
    let(:identity_block) { presenter.blocks.first }
    let(:economic_block) { presenter.blocks.last }

    describe '#status' do
      it 'returns loading when any API is pending' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'pending' },
          'rne' => { 'status' => 'completed' }
        })

        expect(identity_block.status).to eq('loading')
      end

      it 'returns loading when any API is processing' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'processing' },
          'rne' => { 'status' => 'completed' }
        })

        expect(identity_block.status).to eq('loading')
      end

      it 'returns failed when any API failed and none are pending/processing' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'failed' },
          'rne' => { 'status' => 'completed' }
        })

        expect(identity_block.status).to eq('failed')
      end

      it 'returns completed when all APIs are completed' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'completed' },
          'rne' => { 'status' => 'completed' }
        })

        expect(identity_block.status).to eq('completed')
      end
    end

    describe '#loading?, #completed?, #failed?, #done?' do
      it 'correctly identifies loading state' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'processing' },
          'rne' => { 'status' => 'pending' }
        })

        expect(identity_block).to be_loading
        expect(identity_block).not_to be_completed
        expect(identity_block).not_to be_failed
        expect(identity_block).not_to be_done
      end

      it 'correctly identifies completed state' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'completed' },
          'rne' => { 'status' => 'completed' }
        })

        expect(identity_block).not_to be_loading
        expect(identity_block).to be_completed
        expect(identity_block).not_to be_failed
        expect(identity_block).to be_done
      end

      it 'correctly identifies failed state' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'failed' },
          'rne' => { 'status' => 'completed' }
        })

        expect(identity_block).not_to be_loading
        expect(identity_block).not_to be_completed
        expect(identity_block).to be_failed
        expect(identity_block).to be_done
      end
    end

    describe '#success_message and #error_message' do
      it 'returns the configured messages' do
        expect(identity_block.success_message).to eq('L\'ensemble des informations et documents ont été récupérés')
        expect(identity_block.error_message).to include('n\'ont pas pu être récupérées')
      end
    end
  end
end
