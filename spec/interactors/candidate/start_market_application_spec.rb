# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::StartMarketApplication do
  include ActiveJob::TestHelper

  let(:market_application) { create(:market_application) }

  it 'notifies the platform with the start date' do
    freeze_time do
      expect { described_class.call(market_application:) }
        .to have_enqueued_job(MarketApplicationStartedWebhookJob)
        .with(market_application.id, started_at: Time.current.floor(6))
    end
  end

  it 'does not notify the platform again once the application is started' do
    described_class.call(market_application:)

    expect { described_class.call(market_application: MarketApplication.find(market_application.id)) }
      .not_to have_enqueued_job(MarketApplicationStartedWebhookJob)
  end
end
