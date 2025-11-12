# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Urssaf::MapUrssafApiData, type: :interactor do
  let(:public_market) { create(:public_market, :completed) }
  let(:market_type) { MarketType.find_or_create_by(code: public_market.market_type_codes.first) }
  let(:market_attribute1) do
    attr = create(
      :market_attribute,
      :radio_with_justification_required,
      api_key: 'declarations_cotisations_sociales',
      api_name: 'urssaf_attestation_vigilance',
      public_markets: [public_market]
    )
    attr.market_types << market_type
    attr
  end

  let(:market_attribute2) do
    attr = create(
      :market_attribute,
      :radio_with_justification_required,
      api_key: 'travailleurs_handicapes',
      api_name: 'urssaf_attestation_vigilance',
      public_markets: [public_market]
    )
    attr.market_types << market_type
    attr
  end

  let(:market_application) { create(:market_application, public_market:) }
  let(:document_io) { StringIO.new('fake pdf content') }
  let(:document_hash) do
    {
      io: document_io,
      filename: 'attestation.pdf',
      content_type: 'application/pdf'
    }
  end

  let(:bundled_data) do
    OpenStruct.new(
      data: OpenStruct.new(
        declarations_cotisations_sociales: document_hash,
        travailleurs_handicapes: document_hash
      )
    )
  end
  let(:context) do
    OpenStruct.new(
      market_application:,
      bundled_data:
    )
  end

  it 'attaches the document to both URSSAF responses and sets them as auto' do
    described_class.call(context)
    responses = market_application.market_attribute_responses.where(
      market_attribute: [market_attribute1, market_attribute2]
    )
    expect(responses.size).to eq(2)
    responses.each do |response|
      expect(response.documents.attached?).to be true
      expect(response.source).to eq('auto')
      expect(response.value['radio_choice']).to eq('yes') if response.value.is_a?(Hash)
    end
  end
end
