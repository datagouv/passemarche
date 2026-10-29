# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Candidate::PrefillEmailAttributeResponses do
  let(:public_market) { create(:public_market, :completed, :multi_type) }
  let(:market_application) { create(:market_application, public_market:) }
  let(:works_type) { MarketType.find_by!(code: 'works') }
  let(:services_type) { MarketType.find_by!(code: 'services') }
  let!(:works_email_attribute) do
    create(:market_attribute, :email, public_markets: [public_market], market_types: [works_type])
  end
  let!(:services_email_attribute) do
    create(:market_attribute, :email, public_markets: [public_market], market_types: [services_type])
  end

  before do
    allow(SiretValidator).to receive(:valid?).and_return(true)
    market_application.lots = [public_market.lots.find_by!(name: 'Prestations SI')]
  end

  it 'prefills the email attributes of the declared lot types only' do
    described_class.call(market_application:, candidate_email: 'candidat@example.com')

    expect(market_application.market_attribute_responses.map(&:market_attribute))
      .to contain_exactly(services_email_attribute)
  end
end
