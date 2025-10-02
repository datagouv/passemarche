# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::CapacitesTechniquesProfessionnellesRealisationsLivraisonsCinqAns,
  type: :model do
  let(:market_application) { create(:market_application) }
  let(:market_attribute) do
    create(:market_attribute,
      input_type: :capacites_techniques_professionnelles_realisations_livraisons_cinq_ans,
      required: true)
  end

  subject(:response) do
    described_class.new(
      market_application:,
      market_attribute:,
      value:
    )
  end

  describe '.item_schema' do
    it 'defines all required fields' do
      schema = described_class.item_schema

      expect(schema.keys).to match_array(%w[
        resume
        date_debut
        date_fin
        montant
        description
        attestation_bonne_execution
      ])
    end

    it 'marks resume as required string' do
      schema = described_class.item_schema
      expect(schema['resume']).to eq({ type: 'string', required: true })
    end

    it 'marks dates as required' do
      schema = described_class.item_schema
      expect(schema['date_debut']).to eq({ type: 'date', required: true })
      expect(schema['date_fin']).to eq({ type: 'date', required: true })
    end

    it 'marks montant as required integer' do
      schema = described_class.item_schema
      expect(schema['montant']).to eq({ type: 'integer', required: true })
    end

    it 'marks description as required text' do
      schema = described_class.item_schema
      expect(schema['description']).to eq({ type: 'text', required: true })
    end

    it 'marks attestation as optional file' do
      schema = described_class.item_schema
      expect(schema['attestation_bonne_execution']).to eq({ type: 'file', required: false })
    end
  end

  describe '#item_prefix' do
    let(:value) { nil }

    it 'returns "realisation"' do
      expect(response.item_prefix).to eq('realisation')
    end
  end

  describe '#specialized_document_fields' do
    let(:value) { nil }

    it 'includes attestation_bonne_execution' do
      expect(response.specialized_document_fields).to eq(['attestation_bonne_execution'])
    end
  end

  describe '#cleanup_old_specialized_documents?' do
    let(:value) { nil }

    it 'returns false to allow multiple attestations per realisation' do
      expect(response.cleanup_old_specialized_documents?).to be false
    end
  end

  describe 'aliases' do
    let(:value) do
      {
        'items' => {
          '1738234567890' => { 'resume' => 'Test work' }
        }
      }
    end

    it 'aliases realisations to items' do
      expect(response.realisations).to eq(response.items)
    end

    it 'aliases realisations= to items=' do
      response.realisations = { '123' => { 'resume' => 'New' } }
      expect(response.items).to eq({ '123' => { 'resume' => 'New' } })
    end

    it 'aliases realisations_ordered to items_ordered' do
      expect(response.realisations_ordered).to eq(response.items_ordered)
    end
  end

  describe '#realisation_attestations' do
    let(:value) { { 'items' => { '1738234567890' => {} } } }
    let(:file) { fixture_file_upload('test.pdf', 'application/pdf') }

    before do
      response.save!
      response.attach_specialized_document('1738234567890', 'attestation_bonne_execution', file)
    end

    it 'retrieves attestations for specific realisation' do
      attestations = response.realisation_attestations('1738234567890')
      expect(attestations).to be_present
      expect(attestations.size).to eq(1)
      expect(attestations.first.filename.to_s).to eq('test.pdf')
    end
  end

  describe 'validations' do
    context 'when field is not required' do
      let(:market_attribute) do
        create(:market_attribute,
          input_type: :capacites_techniques_professionnelles_realisations_livraisons_cinq_ans,
          required: false)
      end

      context 'with empty value' do
        let(:value) { nil }

        it 'is valid' do
          expect(response).to be_valid
        end
      end

      context 'with partial data' do
        let(:value) do
          {
            'items' => {
              '1738234567890' => {
                'resume' => 'Test'
              }
            }
          }
        end

        it 'is valid' do
          expect(response).to be_valid
        end
      end
    end

    context 'when field is required' do
      let(:market_attribute) do
        create(:market_attribute,
          input_type: :capacites_techniques_professionnelles_realisations_livraisons_cinq_ans,
          required: true)
      end

      context 'with complete valid data' do
        let(:value) do
          {
            'items' => {
              '1738234567890' => {
                'resume' => 'Construction du bâtiment municipal',
                'date_debut' => '2023-01-01',
                'date_fin' => '2023-12-31',
                'montant' => 500_000,
                'description' => 'Construction complète incluant gros œuvre et finitions'
              }
            }
          }
        end

        it 'is valid' do
          expect(response).to be_valid
        end
      end

      context 'with missing resume' do
        let(:value) do
          {
            'items' => {
              '1738234567890' => {
                'date_debut' => '2023-01-01',
                'date_fin' => '2023-12-31',
                'montant' => 500_000,
                'description' => 'Description complète'
              }
            }
          }
        end

        it 'is invalid' do
          expect(response).not_to be_valid
          expect(response.errors[:value]).to include(match(/resume is required/))
        end
      end

      context 'with missing date_debut' do
        let(:value) do
          {
            'items' => {
              '1738234567890' => {
                'resume' => 'Test',
                'date_fin' => '2023-12-31',
                'montant' => 500_000,
                'description' => 'Description'
              }
            }
          }
        end

        it 'is invalid' do
          expect(response).not_to be_valid
          expect(response.errors[:value]).to include(match(/date_debut is required/))
        end
      end

      context 'with missing date_fin' do
        let(:value) do
          {
            'items' => {
              '1738234567890' => {
                'resume' => 'Test',
                'date_debut' => '2023-01-01',
                'montant' => 500_000,
                'description' => 'Description'
              }
            }
          }
        end

        it 'is invalid' do
          expect(response).not_to be_valid
          expect(response.errors[:value]).to include(match(/date_fin is required/))
        end
      end

      context 'with missing montant' do
        let(:value) do
          {
            'items' => {
              '1738234567890' => {
                'resume' => 'Test',
                'date_debut' => '2023-01-01',
                'date_fin' => '2023-12-31',
                'description' => 'Description'
              }
            }
          }
        end

        it 'is invalid' do
          expect(response).not_to be_valid
          expect(response.errors[:value]).to include(match(/montant is required/))
        end
      end

      context 'with missing description' do
        let(:value) do
          {
            'items' => {
              '1738234567890' => {
                'resume' => 'Test',
                'date_debut' => '2023-01-01',
                'date_fin' => '2023-12-31',
                'montant' => 500_000
              }
            }
          }
        end

        it 'is invalid' do
          expect(response).not_to be_valid
          expect(response.errors[:value]).to include(match(/description is required/))
        end
      end

      context 'with date_fin before date_debut' do
        let(:value) do
          {
            'items' => {
              '1738234567890' => {
                'resume' => 'Test',
                'date_debut' => '2023-12-31',
                'date_fin' => '2023-01-01',
                'montant' => 500_000,
                'description' => 'Description'
              }
            }
          }
        end

        it 'is invalid' do
          expect(response).not_to be_valid
          expect(response.errors[:value]).to include(match(/date_fin must be after or equal to date_debut/))
        end
      end

      context 'with date_fin equal to date_debut' do
        let(:value) do
          {
            'items' => {
              '1738234567890' => {
                'resume' => 'Test',
                'date_debut' => '2023-06-15',
                'date_fin' => '2023-06-15',
                'montant' => 500_000,
                'description' => 'Description'
              }
            }
          }
        end

        it 'is valid' do
          expect(response).to be_valid
        end
      end

      context 'with invalid date format' do
        let(:value) do
          {
            'items' => {
              '1738234567890' => {
                'resume' => 'Test',
                'date_debut' => '01/01/2023',
                'date_fin' => '2023-12-31',
                'montant' => 500_000,
                'description' => 'Description'
              }
            }
          }
        end

        it 'is invalid' do
          expect(response).not_to be_valid
          expect(response.errors[:value]).to include(match(/date_debut must be in YYYY-MM-DD format/))
        end
      end

      context 'with negative montant' do
        let(:value) do
          {
            'items' => {
              '1738234567890' => {
                'resume' => 'Test',
                'date_debut' => '2023-01-01',
                'date_fin' => '2023-12-31',
                'montant' => -500_000,
                'description' => 'Description'
              }
            }
          }
        end

        it 'is invalid' do
          expect(response).not_to be_valid
          expect(response.errors[:value]).to include(match(/montant must be a positive integer/))
        end
      end

      context 'with zero montant' do
        let(:value) do
          {
            'items' => {
              '1738234567890' => {
                'resume' => 'Test',
                'date_debut' => '2023-01-01',
                'date_fin' => '2023-12-31',
                'montant' => 0,
                'description' => 'Description'
              }
            }
          }
        end

        it 'is invalid' do
          expect(response).not_to be_valid
          expect(response.errors[:value]).to include(match(/montant must be a positive integer/))
        end
      end
    end
  end

  describe '#assign_attributes with realisation_TIMESTAMP_field pattern' do
    let(:value) { nil }
    let(:timestamp1) { '1738234567890' }
    let(:timestamp2) { '1738234567891' }

    it 'creates realisation from form parameters' do
      response.assign_attributes(
        "realisation_#{timestamp1}_resume" => 'Projet de construction',
        "realisation_#{timestamp1}_date_debut" => '2023-01-01',
        "realisation_#{timestamp1}_date_fin" => '2023-12-31',
        "realisation_#{timestamp1}_montant" => '500000',
        "realisation_#{timestamp1}_description" => 'Description complète du projet'
      )

      expect(response.realisations[timestamp1]).to eq({
        'resume' => 'Projet de construction',
        'date_debut' => '2023-01-01',
        'date_fin' => '2023-12-31',
        'montant' => 500_000,
        'description' => 'Description complète du projet'
      })
    end

    it 'creates multiple realisations' do
      response.assign_attributes(
        "realisation_#{timestamp1}_resume" => 'Projet 1',
        "realisation_#{timestamp1}_date_debut" => '2023-01-01',
        "realisation_#{timestamp1}_date_fin" => '2023-06-30',
        "realisation_#{timestamp1}_montant" => '300000',
        "realisation_#{timestamp1}_description" => 'Description 1',
        "realisation_#{timestamp2}_resume" => 'Projet 2',
        "realisation_#{timestamp2}_date_debut" => '2023-07-01',
        "realisation_#{timestamp2}_date_fin" => '2023-12-31',
        "realisation_#{timestamp2}_montant" => '450000',
        "realisation_#{timestamp2}_description" => 'Description 2'
      )

      expect(response.realisations.keys).to match_array([timestamp1, timestamp2])
      expect(response.realisations[timestamp1]['resume']).to eq('Projet 1')
      expect(response.realisations[timestamp2]['resume']).to eq('Projet 2')
    end

    it 'handles _destroy flag' do
      response.assign_attributes(
        "realisation_#{timestamp1}_resume" => 'Projet 1',
        "realisation_#{timestamp2}_resume" => 'Projet 2'
      )
      expect(response.realisations.keys).to match_array([timestamp1, timestamp2])

      response.assign_attributes("realisation_#{timestamp1}__destroy" => '1')
      expect(response.realisations.keys).to eq([timestamp2])
    end
  end

  describe 'specialized document handling' do
    let(:value) { { 'items' => { '1738234567890' => {} } } }
    let(:file) { fixture_file_upload('test.pdf', 'application/pdf') }

    before { response.save! }

    it 'attaches attestation with correct metadata' do
      response.attach_specialized_document('1738234567890', 'attestation_bonne_execution', file)

      doc = response.documents.first
      expect(doc.metadata['field_type']).to eq('specialized')
      expect(doc.metadata['item_timestamp']).to eq('1738234567890')
      expect(doc.metadata['field_name']).to eq('attestation_bonne_execution')
    end

    it 'keeps all attestations when multiple are uploaded' do
      response.attach_specialized_document('1738234567890', 'attestation_bonne_execution', file)
      expect(response.documents.count).to eq(1)

      new_file = fixture_file_upload('test.pdf', 'application/pdf')
      response.attach_specialized_document('1738234567890', 'attestation_bonne_execution', new_file)

      expect(response.documents.count).to eq(2)
    end

    it 'retrieves all attestations for a realisation' do
      response.attach_specialized_document('1738234567890', 'attestation_bonne_execution', file)
      first_doc_id = response.documents.first.id

      sleep 0.1

      new_file = fixture_file_upload('test.pdf', 'application/pdf')
      response.attach_specialized_document('1738234567890', 'attestation_bonne_execution', new_file)

      retrieved = response.realisation_attestations('1738234567890')
      expect(retrieved.size).to eq(2)
      expect(retrieved.map(&:id)).to include(first_doc_id)
    end
  end

  describe 'integration with MarketApplication' do
    let(:value) { nil }

    it 'can be saved via market_application.update' do
      timestamp = Time.now.to_i.to_s

      result = market_application.update(
        market_attribute_responses_attributes: {
          '0' => {
            id: '',
            market_attribute_id: market_attribute.id.to_s,
            type: 'CapacitesTechniquesProfessionnellesRealisationsLivraisonsCinqAns',
            "realisation_#{timestamp}_resume" => 'Construction école',
            "realisation_#{timestamp}_date_debut" => '2023-01-01',
            "realisation_#{timestamp}_date_fin" => '2023-12-31',
            "realisation_#{timestamp}_montant" => '750000',
            "realisation_#{timestamp}_description" => 'Construction complète'
          }
        }
      )

      expect(result).to be true
      saved_response = market_application.market_attribute_responses.last
      expect(saved_response.realisations[timestamp]['resume']).to eq('Construction école')
    end

    it 'can handle multiple file uploads for attestations' do
      timestamp = Time.now.to_i.to_s

      # Create response first
      response = described_class.create!(
        market_application:,
        market_attribute:
      )

      # Create multiple test files
      file1 = fixture_file_upload('test.pdf', 'application/pdf')
      file2 = fixture_file_upload('test.pdf', 'application/pdf')
      file3 = fixture_file_upload('test.pdf', 'application/pdf')

      # Assign attributes including array of files
      response.assign_attributes(
        "realisation_#{timestamp}_resume" => 'Projet avec attestations',
        "realisation_#{timestamp}_date_debut" => '2023-01-01',
        "realisation_#{timestamp}_date_fin" => '2023-12-31',
        "realisation_#{timestamp}_montant" => '500000',
        "realisation_#{timestamp}_description" => 'Test multiple files',
        "realisation_#{timestamp}_attestation_bonne_execution" => [file1, file2, file3]
      )

      expect(response.save).to be true

      attestations = response.realisation_attestations(timestamp)
      expect(attestations.size).to eq(3)
      expect(attestations.map { |att| att.filename.to_s }).to all(eq('test.pdf'))
    end
  end
end
