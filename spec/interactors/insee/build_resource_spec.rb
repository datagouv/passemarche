# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Insee::BuildResource, type: :interactor do
  include ApiResponses::InseeResponses

  let(:siret) { '41816609600069' }
  let(:response_body) { insee_etablissement_success_response(siret:) }
  let(:response) { instance_double(Net::HTTPOK, body: response_body) }

  describe '.call' do
    subject { described_class.call(response:) }

    context 'when the response contains valid data' do
      it_behaves_like 'a successful resource builder'
      it_behaves_like 'resource field extraction', :siret, '41816609600069'
      it_behaves_like 'resource field extraction', :category, 'PME'
    end

    context 'with different category values' do
      context 'when category is GE (Grande Entreprise)' do
        let(:response_body) do
          insee_etablissement_success_response(
            siret:,
            overrides: {
              data: {
                unite_legale: {
                  categorie_entreprise: 'GE'
                }
              }
            }
          )
        end

        it_behaves_like 'resource field extraction', :category, 'GE'
      end

      context 'when category is ETI (Entreprise de Taille Intermédiaire)' do
        let(:response_body) do
          insee_etablissement_success_response(
            siret:,
            overrides: {
              data: {
                unite_legale: {
                  categorie_entreprise: 'ETI'
                }
              }
            }
          )
        end

        it_behaves_like 'resource field extraction', :category, 'ETI'
      end

      context 'when category is null' do
        let(:response_body) do
          insee_etablissement_success_response(
            siret:,
            overrides: {
              data: {
                unite_legale: {
                  categorie_entreprise: nil
                }
              }
            }
          )
        end

        it_behaves_like 'resource field extraction', :category, nil
      end
    end

    context 'with different SIRET values' do
      let(:siret) { '13002526500013' }

      it_behaves_like 'resource field extraction', :siret, '13002526500013'
    end
  end
end
