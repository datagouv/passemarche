# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Urssaf::MapUrssafApiData, type: :interactor do
  let(:public_market) { create(:public_market, :completed) }
  let(:market_application) { create(:market_application, public_market:) }
  let(:market_attribute1) do
    create(
      :market_attribute,
      api_name: 'urssaf_attestation_vigilance',
      api_key: 'declarations_cotisations_sociales',
      input_type: 'radio_with_justification_required'
    )
  end

  let(:market_attribute2) do
    create(
      :market_attribute,
      api_name: 'urssaf_attestation_vigilance',
      api_key: 'travailleurs_handicapes',
      input_type: 'radio_with_justification_required'
    )
  end
  let(:document_io) { StringIO.new('fake pdf content') }
  let(:document_hash) do
    {
      io: document_io,
      filename: 'attestation.pdf',
      content_type: 'application/pdf'
    }
  end

  let(:bundled_data) { OpenStruct.new(data: OpenStruct.new(document: document_hash)) }
  let(:context) do
    OpenStruct.new(
      api_name: 'urssaf_attestation_vigilance',
      market_application:,
      bundled_data:
    )
  end

  before do
    public_market.market_attributes << market_attribute1
    public_market.market_attributes << market_attribute2
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
      expect(response.value['radio_choice']).to eq('no') if response.value.is_a?(Hash)
    end
  end
end
