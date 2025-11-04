# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiBlockStatusPresenter do
  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }
  let(:market_application) { create(:market_application, public_market:, siret: '12345678901234') }
  let(:presenter) { ApiBlockStatusPresenter.new(market_application) }

  before do
    allow(SiretValidationService).to receive(:call).and_return(true)
    allow(market_application).to receive(:api_names_to_fetch).and_return(%w[insee rne attestations_fiscales probtp qualibat dgfip_chiffres_affaires])
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
      expect(economic_block.apis).to contain_exactly('attestations_fiscales', 'probtp', 'dgfip_chiffres_affaires')
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
        'qualibat' => { 'status' => 'completed' },
        'dgfip_chiffres_affaires' => { 'status' => 'completed' }
      })

      expect(presenter.all_blocks_done?).to be true
    end

    it 'returns true when all APIs are completed or failed' do
      market_application.update(api_fetch_status: {
        'insee' => { 'status' => 'completed' },
        'rne' => { 'status' => 'failed' },
        'attestations_fiscales' => { 'status' => 'completed' },
        'probtp' => { 'status' => 'completed' },
        'qualibat' => { 'status' => 'failed' },
        'dgfip_chiffres_affaires' => { 'status' => 'completed' }
      })

      expect(presenter.all_blocks_done?).to be true
    end

    it 'returns false when at least one API is processing' do
      market_application.update(api_fetch_status: {
        'insee' => { 'status' => 'completed' },
        'rne' => { 'status' => 'processing' },
        'attestations_fiscales' => { 'status' => 'completed' },
        'probtp' => { 'status' => 'completed' },
        'qualibat' => { 'status' => 'completed' },
        'dgfip_chiffres_affaires' => { 'status' => 'completed' }
      })

      expect(presenter.all_blocks_done?).to be false
    end

    it 'returns false when at least one API is pending' do
      market_application.update(api_fetch_status: {
        'insee' => { 'status' => 'completed' },
        'rne' => { 'status' => 'pending' },
        'attestations_fiscales' => { 'status' => 'completed' },
        'probtp' => { 'status' => 'completed' },
        'qualibat' => { 'status' => 'completed' },
        'dgfip_chiffres_affaires' => { 'status' => 'completed' }
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
        'probtp' => { 'status' => 'pending' },
        'qualibat' => { 'status' => 'pending' },
        'dgfip_chiffres_affaires' => { 'status' => 'pending' }
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
        'qualibat' => { 'status' => 'completed' },
        'dgfip_chiffres_affaires' => { 'status' => 'completed' }
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
        'qualibat' => { 'status' => 'completed' },
        'dgfip_chiffres_affaires' => { 'status' => 'completed' }
      })

      expect(presenter.overall_status_message).to eq('L\'ensemble des informations et documents ont été récupérés')
    end

    it 'returns partial failure message when some blocks failed' do
      market_application.update(api_fetch_status: {
        'insee' => { 'status' => 'completed' },
        'rne' => { 'status' => 'completed' },
        'attestations_fiscales' => { 'status' => 'failed' },
        'probtp' => { 'status' => 'failed' },
        'qualibat' => { 'status' => 'completed' },
        'dgfip_chiffres_affaires' => { 'status' => 'completed' }
      })

      expect(presenter.overall_status_message).to include('bloc(s) n\'ont pas pu être récupérés')
    end

    it 'returns in progress message when not all done' do
      market_application.update(api_fetch_status: {
        'insee' => { 'status' => 'processing' },
        'rne' => { 'status' => 'pending' },
        'attestations_fiscales' => { 'status' => 'pending' },
        'probtp' => { 'status' => 'pending' },
        'qualibat' => { 'status' => 'pending' }
      })

      expect(presenter.overall_status_message).to eq('Récupération en cours, veuillez patienter...')
    end
  end

  describe ApiBlockStatusPresenter::ApiBlock do
    let(:identity_block) { presenter.blocks.first }
    let(:economic_block) { presenter.blocks.second }

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

    describe '#completed_count' do
      it 'returns count of completed APIs when all completed' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'completed' },
          'rne' => { 'status' => 'completed' }
        })

        expect(identity_block.completed_count).to eq(2)
      end

      it 'returns count of completed APIs when some failed' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'completed' },
          'rne' => { 'status' => 'failed' }
        })

        expect(identity_block.completed_count).to eq(1)
      end

      it 'returns 0 when all APIs failed' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'failed' },
          'rne' => { 'status' => 'failed' }
        })

        expect(identity_block.completed_count).to eq(0)
      end

      it 'returns 0 when all APIs pending' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'pending' },
          'rne' => { 'status' => 'pending' }
        })

        expect(identity_block.completed_count).to eq(0)
      end
    end

    describe '#total_count' do
      it 'returns total number of APIs in the block' do
        expect(identity_block.total_count).to eq(2)
        expect(economic_block.total_count).to eq(3)
      end
    end

    describe '#all_completed?' do
      it 'returns true when all APIs completed successfully' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'completed' },
          'rne' => { 'status' => 'completed' }
        })

        expect(identity_block).to be_all_completed
      end

      it 'returns false when any API failed' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'completed' },
          'rne' => { 'status' => 'failed' }
        })

        expect(identity_block).not_to be_all_completed
      end

      it 'returns false when APIs are still pending' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'completed' },
          'rne' => { 'status' => 'pending' }
        })

        expect(identity_block).not_to be_all_completed
      end
    end

    describe '#done_message' do
      it 'returns all_success message when all APIs completed' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'completed' },
          'rne' => { 'status' => 'completed' }
        })

        expect(identity_block.done_message).to eq('L\'ensemble des informations et documents ont été récupérés')
      end

      it 'returns partial_success message when some APIs failed' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'completed' },
          'rne' => { 'status' => 'failed' }
        })

        expect(identity_block.done_message).to eq('Certaines informations ou documents n\'ont pas pu être récupérés automatiquement, nous vous demanderont de compléter ces informations manuellement')
      end

      it 'returns partial_success message when all APIs failed' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'failed' },
          'rne' => { 'status' => 'failed' }
        })

        expect(identity_block.done_message).to eq('Certaines informations ou documents n\'ont pas pu être récupérés automatiquement, nous vous demanderont de compléter ces informations manuellement')
      end
    end

    describe '#status_count_class' do
      it 'returns success class when all completed' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'completed' },
          'rne' => { 'status' => 'completed' }
        })

        expect(identity_block.status_count_class).to eq('api-status-count--success')
      end

      it 'returns warning class when some failed' do
        market_application.update(api_fetch_status: {
          'insee' => { 'status' => 'completed' },
          'rne' => { 'status' => 'failed' }
        })

        expect(identity_block.status_count_class).to eq('api-status-count--warning')
      end
    end
  end
end
