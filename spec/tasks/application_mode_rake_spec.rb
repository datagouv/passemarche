# frozen_string_literal: true

require 'rails_helper'
require 'rake'

RSpec.describe 'application_mode:backfill_solo', type: :task do
  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  before do
    Rake::Task['application_mode:backfill_solo'].reenable
  end

  let(:editor) { create(:editor) }
  let(:public_market) { create(:public_market, :completed, editor:) }

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
  end

  it 'sets application_mode: solo on candidacies left with a nil mode' do
    nil_mode_application = create(:market_application, public_market:, siret: '73282932000074')
    nil_mode_application.update_column(:application_mode, nil)

    Rake::Task['application_mode:backfill_solo'].invoke

    expect(nil_mode_application.reload).to be_solo
  end

  it 'does not touch candidacies that already have a mode' do
    groupement_application = create(:market_application, public_market:, siret: '11122233300014', application_mode: :groupement)

    Rake::Task['application_mode:backfill_solo'].invoke

    expect(groupement_application.reload).to be_groupement
  end
end
