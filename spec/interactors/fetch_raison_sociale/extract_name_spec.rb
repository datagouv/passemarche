# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FetchRaisonSociale::ExtractName, type: :interactor do
  include ApiResponses::InseeResponses

  let(:siret) { '13002526500013' }

  def build_response_body(raison_sociale:)
    insee_etablissement_success_response(
      siret:,
      overrides: {
        data: {
          unite_legale: {
            personne_morale_attributs: { raison_sociale: }
          }
        }
      }
    )
  end

  describe '.call' do
    subject { described_class.call(response:) }

    context 'when raison_sociale is present' do
      let(:response) { instance_double(Net::HTTPOK, body: build_response_body(raison_sociale: 'OCTO TECHNOLOGY')) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'sets raison_sociale in context' do
        expect(subject.raison_sociale).to eq('OCTO TECHNOLOGY')
      end
    end

    context 'when raison_sociale is nil (personne physique)' do
      let(:response) { instance_double(Net::HTTPOK, body: build_response_body(raison_sociale: nil)) }

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'sets raison_sociale to nil' do
        expect(subject.raison_sociale).to be_nil
      end
    end

    context 'when the response is invalid JSON' do
      let(:response) { instance_double(Net::HTTPOK, body: insee_invalid_json_response) }

      it 'fails' do
        expect(subject).to be_failure
      end

      it 'sets an error message' do
        expect(subject.error).to eq('Invalid JSON response')
      end
    end
  end
end
