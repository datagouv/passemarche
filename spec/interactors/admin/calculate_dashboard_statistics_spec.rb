# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::CalculateDashboardStatistics, type: :interactor do
  subject(:result) { described_class.call(editor:) }

  let(:editor) { nil }

  describe '.call' do
    context 'with empty database' do
      it 'returns zero values for all statistics' do
        expect(result.statistics).to include(
          editors_total: 0,
          editors_active: 0,
          markets_total: 0,
          markets_completed: 0,
          markets_active: 0,
          applications_total: 0,
          applications_completed: 0,
          documents_transmitted: 0,
          unique_companies: 0,
          unique_buyers: 0,
          avg_completion_time_seconds: nil,
          auto_fill_rate: nil
        )
      end
    end

    context 'with editors' do
      before do
        create(:editor, :authorized_and_active)
        create(:editor, authorized: true, active: false)
        create(:editor, :inactive)
        create(:editor)
      end

      it 'counts total editors' do
        expect(result.statistics[:editors_total]).to eq(4)
      end

      it 'counts only authorized and active editors' do
        expect(result.statistics[:editors_active]).to eq(1)
      end
    end

    context 'with markets' do
      let!(:editor1) { create(:editor, :authorized_and_active) }
      let!(:editor2) { create(:editor, :authorized_and_active) }
      let!(:completed_market1) { create(:public_market, :completed, editor: editor1, siret: '13002526500013') }
      let!(:completed_market2) { create(:public_market, :completed, editor: editor1, siret: '13002526500021') }
      let!(:active_market) { create(:public_market, editor: editor1, siret: '13002526500039') }
      let!(:other_editor_market) { create(:public_market, :completed, editor: editor2, siret: '13002526500047') }

      context 'without editor filter' do
        it 'counts all markets' do
          expect(result.statistics[:markets_total]).to eq(4)
        end

        it 'counts completed markets' do
          expect(result.statistics[:markets_completed]).to eq(3)
        end

        it 'counts active markets' do
          expect(result.statistics[:markets_active]).to eq(1)
        end

        it 'counts unique buyers by SIRET' do
          expect(result.statistics[:unique_buyers]).to eq(4)
        end
      end

      context 'with editor filter' do
        let(:editor) { editor1 }

        it 'counts only filtered editor markets' do
          expect(result.statistics[:markets_total]).to eq(3)
        end

        it 'counts filtered editor completed markets' do
          expect(result.statistics[:markets_completed]).to eq(2)
        end

        it 'counts filtered editor active markets' do
          expect(result.statistics[:markets_active]).to eq(1)
        end

        it 'counts unique buyers for filtered editor' do
          expect(result.statistics[:unique_buyers]).to eq(3)
        end

        it 'still counts all editors globally' do
          expect(result.statistics[:editors_total]).to eq(2)
          expect(result.statistics[:editors_active]).to eq(2)
        end
      end
    end

    context 'with applications' do
      let!(:editor1) { create(:editor, :authorized_and_active) }
      let!(:editor2) { create(:editor, :authorized_and_active) }
      let!(:market1) { create(:public_market, :completed, editor: editor1) }
      let!(:market2) { create(:public_market, :completed, editor: editor2) }

      let!(:completed_app1) do
        create(:market_application, :completed, :attests_no_exclusion, public_market: market1, siret: '73282932000074')
      end
      let!(:completed_app2) do
        create(:market_application, :completed, :attests_no_exclusion, public_market: market1, siret: '73282932000082')
      end
      let!(:pending_app) do
        create(:market_application, :attests_no_exclusion, public_market: market1, siret: '73282932000074')
      end
      let!(:other_editor_app) do
        create(:market_application, :completed, :attests_no_exclusion, public_market: market2, siret: '73282932000090')
      end

      context 'without editor filter' do
        it 'counts all applications' do
          expect(result.statistics[:applications_total]).to eq(4)
        end

        it 'counts completed applications' do
          expect(result.statistics[:applications_completed]).to eq(3)
        end

        it 'counts unique companies by SIRET' do
          expect(result.statistics[:unique_companies]).to eq(3)
        end
      end

      context 'with editor filter' do
        let(:editor) { editor1 }

        it 'counts only filtered editor applications' do
          expect(result.statistics[:applications_total]).to eq(3)
        end

        it 'counts filtered editor completed applications' do
          expect(result.statistics[:applications_completed]).to eq(2)
        end

        it 'counts unique companies for filtered editor' do
          expect(result.statistics[:unique_companies]).to eq(2)
        end
      end
    end

    context 'with completion time calculation' do
      let!(:editor1) { create(:editor, :authorized_and_active) }
      let!(:market) { create(:public_market, :completed, editor: editor1) }

      before do
        create(
          :market_application, :attests_no_exclusion,
          public_market: market,
          siret: '73282932000074',
          created_at: 10.minutes.ago,
          completed_at: Time.current
        )
        create(
          :market_application, :attests_no_exclusion,
          public_market: market,
          siret: '73282932000082',
          created_at: 20.minutes.ago,
          completed_at: Time.current
        )
      end

      it 'calculates average completion time in seconds' do
        avg_time = result.statistics[:avg_completion_time_seconds]
        expect(avg_time).to be_within(60).of(900)
      end
    end

    context 'with no completed applications' do
      let!(:editor1) { create(:editor, :authorized_and_active) }
      let!(:market) { create(:public_market, :completed, editor: editor1) }

      before do
        create(:market_application, :attests_no_exclusion, public_market: market, siret: '73282932000074')
      end

      it 'returns nil for average completion time' do
        expect(result.statistics[:avg_completion_time_seconds]).to be_nil
      end
    end

    context 'with responses and auto-fill rate' do
      let!(:editor1) { create(:editor, :authorized_and_active) }
      let!(:market) { create(:public_market, :completed, editor: editor1) }
      let!(:application) { create(:market_application, :attests_no_exclusion, public_market: market, siret: '73282932000074') }

      before do
        create(:market_attribute_response_text_input, market_application: application, source: :auto)
        create(:market_attribute_response_text_input, market_application: application, source: :auto)
        create(:market_attribute_response_text_input, market_application: application, source: :manual)
      end

      it 'calculates auto-fill rate' do
        expect(result.statistics[:auto_fill_rate]).to be_within(0.01).of(0.67)
      end
    end

    context 'with file attachments' do
      let!(:editor1) { create(:editor, :authorized_and_active) }
      let!(:market) { create(:public_market, :completed, editor: editor1) }
      let!(:application) { create(:market_application, :attests_no_exclusion, public_market: market, siret: '73282932000074') }

      before do
        create(:market_attribute_response_file_upload, market_application: application)
        create(:market_attribute_response_file_upload, market_application: application)
        create(:market_attribute_response_text_input, market_application: application)
      end

      it 'counts only file attachment responses' do
        expect(result.statistics[:documents_transmitted]).to eq(2)
      end
    end

    context 'with no responses' do
      let!(:editor1) { create(:editor, :authorized_and_active) }
      let!(:market) { create(:public_market, :completed, editor: editor1) }

      before do
        create(:market_application, :attests_no_exclusion, public_market: market, siret: '73282932000074')
      end

      it 'returns nil for auto-fill rate when no responses exist' do
        expect(result.statistics[:auto_fill_rate]).to be_nil
      end
    end
  end
end
