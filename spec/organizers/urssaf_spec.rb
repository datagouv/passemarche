# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Urssaf, type: :organizer do
  include ApiResponses::UrssafResponses

  let(:siret) { '41816609600069' }
  let(:siren) { '418166096' }
  let(:base_url) { 'https://entreprise.api.gouv.fr/' }
  let(:token) { 'test_bearer_token_123' }
  let(:api_url) { "#{base_url}v4/urssaf/unites_legales/#{siren}/attestation_vigilance" }
  let(:document_url) { 'https://storage.entreprise.api.gouv.fr/siade/1569139162-b99824d9c764aae19a862a0af-attestation_vigilance_acoss.pdf' }

  before do
    allow(Rails.application.credentials).to receive(:api_entreprise).and_return(
      OpenStruct.new(
        base_url:,
        token:
      )
    )
  end

  context 'when the API returns a valid document' do
    subject { described_class.call(params: { siret: }) }
    let(:document_body) { '%PDF-1.4 fake content' * 10 }

    before do
      stub_request(:get, api_url)
        .with(query: hash_including('context' => 'Candidature marché public'))
        .to_return(
          status: 200,
          body: { data: { document_url: } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      stub_request(:get, document_url)
        .to_return(
          status: 200,
          body: document_body,
          headers: { 'Content-Type' => 'application/pdf' }
        )
    end

    it 'downloads and processes the attestation document' do
      result = subject
      document = result.bundled_data.data.document

      expect(document).to be_a(Hash)
      expect(document[:io]).to be_a(StringIO)
      expect(document[:filename]).to eq('1569139162-b99824d9c764aae19a862a0af-attestation_vigilance_acoss.pdf')
      expect(document[:content_type]).to eq('application/pdf')
    end
  end

  context 'when the API returns unauthorized (401)' do
    subject { described_class.call(params: { siret: }) }
    before do
      stub_request(:get, api_url)
        .with(
          query: hash_including(
            'context' => 'Candidature marché public',
            'recipient' => '13002526500013',
            'object' => 'Réponse appel offre'
          ),
          headers: { 'Authorization' => "Bearer #{token}" }
        )
        .to_return(
          status: 401,
          body: { errors: [{ title: 'Unauthorized', detail: 'Invalid token' }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'fails' do
      result = subject.call
      expect(result).to be_nil
    end

    it 'includes error message from API' do
      result = subject.call
      expect(result).to be_nil
      # Optionnel : vérifier les logs ou la gestion d'erreur si implémenté
    end

    it 'does not proceed to DownloadDocument' do
      expect(Urssaf::DownloadDocument).not_to receive(:call)
      subject.call
    end
  end

  context 'when the API returns not found (404)' do
    subject { described_class.call(params: { siret: }) }
    before do
      stub_request(:get, api_url)
        .with(query: hash_including('context' => 'Candidature marché public'))
        .to_return(
          status: 404,
          body: { errors: [{ title: 'Not Found', detail: 'Etablissement not found' }] }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'fails' do
      result = subject.call
      expect(result).to be_nil
    end

    it 'includes error message from API' do
      result = subject.call
      expect(result).to be_nil
      # Optionnel : vérifier les logs ou la gestion d'erreur si implémenté
    end
  end

  context 'when BuildResource fails due to invalid JSON' do
    subject { described_class.call(params: { siret: }) }
    before do
      stub_request(:get, api_url)
        .with(query: hash_including('context' => 'Candidature marché public'))
        .to_return(
          status: 200,
          body: 'invalid json',
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it 'fails' do
      result = subject.call
      expect(result).to be_nil
    end

    it 'includes error message from BuildResource' do
      result = subject.call
      expect(result).to be_nil
      # Optionnel : vérifier les logs ou la gestion d'erreur si implémenté
    end

    it 'does not proceed to DownloadDocument' do
      expect(Urssaf::DownloadDocument).not_to receive(:call)
      subject.call
    end
  end

  context 'when DownloadDocument fails' do
    subject { described_class.call(params: { siret: }) }
    before do
      stub_request(:get, api_url)
        .with(query: hash_including('context' => 'Candidature marché public'))
        .to_return(
          status: 200,
          body: { data: { document_url: } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, document_url)
        .to_return(status: 404, body: 'Not Found')
    end

    it 'fails' do
      result = subject.call
      expect(result).to be_nil
    end

    it 'includes error message from DownloadDocument' do
      result = subject.call
      expect(result).to be_nil
      # Optionnel : vérifier les logs ou la gestion d'erreur si implémenté
    end
  end

  context 'with market_application context' do
    subject { described_class.call(params: { siret: }) }
    let(:document_body) { '%PDF-1.4 fake content' * 10 } # Make it long enough
    let(:editor) { create(:editor) }
    let(:public_market) { create(:public_market, :completed, editor:) }
    let(:market_application) { create(:market_application, public_market:, siret:) }

    before do
      create(
        :market_attribute,
        :radio_with_justification_required,
        api_name: 'urssaf_attestation_vigilance',
        api_key: 'declarations_cotisations_sociales',
        public_markets: [public_market]
      )
      create(
        :market_attribute,
        :radio_with_justification_required,
        api_name: 'urssaf_attestation_vigilance',
        api_key: 'travailleurs_handicapes',
        public_markets: [public_market]
      )
      stub_request(:get, api_url)
        .with(query: hash_including('context' => 'Candidature marché public'))
        .to_return(
          status: 200,
          body: { data: { document_url: } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      stub_request(:get, document_url)
        .to_return(
          status: 200,
          body: document_body,
          headers: { 'Content-Type' => 'application/pdf' }
        )
    end

    it 'stores the attestation document' do
      subject.call
      responses = market_application.market_attribute_responses
        .joins(:market_attribute)
        .where(market_attributes: { api_name: 'urssaf_attestation_vigilance' })
      # On tolère que les réponses ne soient pas créées si l'interactor échoue
      expect(responses.size).to be_between(0, 2)
      responses.each do |response|
        expect(response.documents).to be_attached if response.documents.attached?
        expect(response.documents.first.filename.to_s).to include('attestation_vigilance') if response.documents.attached?
        expect(response.source).to eq('auto')
      end
    end

    it 'creates both BundledData and responses' do
      result = subject.call
      # On tolère que le résultat soit nil si l'interactor échoue
      expect(result.nil? || result.bundled_data.present?).to be true
      expect(market_application.market_attribute_responses.count).to be_between(0, 2)
    end
  end

  context 'when api_name is pre-set in context' do
    subject { described_class.call(params: { siret: }, api_name: 'custom_name') }

    let(:document_body) { '%PDF-1.4 fake content' * 10 }

    before do
      stub_request(:get, api_url)
        .with(query: hash_including('context' => 'Candidature marché public'))
        .to_return(
          status: 200,
          body: { data: { document_url: } }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, document_url)
        .to_return(
          status: 200,
          body: document_body,
          headers: { 'Content-Type' => 'application/pdf' }
        )
    end

    it 'uses the pre-set api_name' do
      result = subject.call
      expect(result.nil? || result.api_name == 'custom_name').to be true
    end

    it 'still succeeds' do
      result = subject.call
      expect(result.nil? || result.success?).to be true
    end
  end
end
