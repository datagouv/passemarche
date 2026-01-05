# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MapApiData, type: :interactor do
  describe '.call' do
    let(:public_market) { create(:public_market, :completed) }
    let(:market_application) { create(:market_application, public_market:) }
    let(:resource) { Resource.new(siret: '41816609600069', category: 'PME') }
    let(:bundled_data) { BundledData.new(data: resource, context: {}) }
    let(:api_name) { 'Insee' }

    subject do
      described_class.call(
        market_application:,
        api_name:,
        bundled_data:
      )
    end

    context 'when public_market has attributes from the API' do
      let!(:siret_attribute) do
        create(:market_attribute, :text_input, :from_api,
          key: 'identite_entreprise_identification_siret',
          api_name: 'Insee',
          api_key: 'siret',
          public_markets: [public_market])
      end

      let!(:category_attribute) do
        create(:market_attribute, :text_input, :from_api,
          key: 'identite_entreprise_identification_categorie',
          api_name: 'Insee',
          api_key: 'category',
          public_markets: [public_market])
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates market_attribute_responses for each API field' do
        expect { subject }.to change { market_application.market_attribute_responses.count }.by(2)
      end

      it 'populates the SIRET response with correct value' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: siret_attribute)
        expect(response.text).to eq('41816609600069')
      end

      it 'populates the category response with correct value' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: category_attribute)
        expect(response.text).to eq('PME')
      end

      it 'sets the correct STI type for responses' do
        subject
        responses = market_application.market_attribute_responses.reload
        expect(responses.map(&:type).uniq).to eq(['TextInput'])
      end

      it 'sets source to auto for new responses' do
        subject
        responses = market_application.market_attribute_responses.reload
        expect(responses.map(&:source).uniq).to eq(['auto'])
      end

      context 'when responses already exist' do
        before do
          create(:market_attribute_response,
            market_application:,
            market_attribute: siret_attribute,
            value: { 'text' => 'old_value' })
        end

        it 'updates existing responses instead of creating new ones' do
          expect { subject }.to change { market_application.market_attribute_responses.count }.by(1)
        end

        it 'updates the value of existing response' do
          subject
          response = market_application.market_attribute_responses.find_by(market_attribute: siret_attribute)
          expect(response.text).to eq('41816609600069')
        end

        it 'sets source to auto for updated responses' do
          subject
          response = market_application.market_attribute_responses.find_by(market_attribute: siret_attribute)
          expect(response.source).to eq('auto')
        end
      end

      context 'when response has manual_after_api_failure source' do
        before do
          create(:market_attribute_response,
            market_application:,
            market_attribute: siret_attribute,
            value: { 'text' => 'manually_entered' },
            source: :manual_after_api_failure)
        end

        it 'does not change source from manual_after_api_failure' do
          subject
          response = market_application.market_attribute_responses.find_by(market_attribute: siret_attribute)
          expect(response.source).to eq('manual_after_api_failure')
        end

        it 'still updates the value even with manual_after_api_failure source' do
          subject
          response = market_application.market_attribute_responses.find_by(market_attribute: siret_attribute)
          expect(response.text).to eq('41816609600069')
        end
      end

      context 'when resource has nil values' do
        let(:resource) { Resource.new(siret: '41816609600069', category: nil) }

        it 'succeeds' do
          expect(subject).to be_success
        end

        it 'stores nil values correctly' do
          subject
          response = market_application.market_attribute_responses.find_by(market_attribute: category_attribute)
          expect(response.text).to be_nil
        end
      end
    end

    context 'when public_market has no attributes from this API' do
      let!(:other_attribute) do
        create(:market_attribute, :text_input, :from_api,
          key: 'other_field',
          api_name: 'OtherAPI',
          api_key: 'other',
          public_markets: [public_market])
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'does not create any responses' do
        expect { subject }.not_to change { market_application.market_attribute_responses.count }
      end
    end

    context 'when resource contains radio_with_file_and_text data' do
      let(:ess_value) { { 'radio_choice' => 'yes', 'text' => 'ESS certified company' } }
      let(:resource) { Resource.new(ess: ess_value) }
      let(:bundled_data) { BundledData.new(data: resource) }

      let!(:ess_attribute) do
        create(:market_attribute, :radio_with_file_and_text, :from_api,
          key: 'capacites_techniques_professionnelles_certificats_ess',
          api_name:,
          api_key: 'ess',
          public_markets: [public_market])
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates market_attribute_response' do
        expect { subject }.to change { market_application.market_attribute_responses.count }.by(1)
      end

      it 'stores radio_choice in value field' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: ess_attribute)
        expect(response.radio_choice).to eq('yes')
      end

      it 'stores text in value field' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: ess_attribute)
        expect(response.text).to eq('ESS certified company')
      end

      it 'sets source to auto' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: ess_attribute)
        expect(response.source).to eq('auto')
      end
    end

    context 'when market_application is not provided' do
      subject do
        described_class.call(
          api_name:,
          bundled_data:
        )
      end

      it 'succeeds without doing anything' do
        expect(subject).to be_success
      end
    end

    context 'when bundled_data is missing' do
      subject do
        described_class.call(
          market_application:,
          api_name:
        )
      end

      it 'fails with an error' do
        expect(subject).to be_failure
      end

      it 'sets an error message' do
        result = subject
        expect(result.error).to be_present
      end
    end

    context 'when resource contains document hash' do
      let(:document_io) { StringIO.new('PDF content') }
      let(:document_hash) do
        {
          io: document_io,
          filename: 'attestation_fiscale_418166096.pdf',
          content_type: 'application/pdf',
          metadata: { source: 'api_attestations_fiscales', api_name: 'attestations_fiscales' }
        }
      end
      let(:resource) { Resource.new(attestation: document_hash) }

      let!(:attestation_attribute) do
        create(:market_attribute, :file_upload, :from_api,
          key: 'fiscalite_attestations_fiscales',
          api_name: 'Insee',
          api_key: 'attestation',
          public_markets: [public_market])
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates market_attribute_response for the document' do
        expect { subject }.to change { market_application.market_attribute_responses.count }.by(1)
      end

      it 'attaches the document to the response' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: attestation_attribute)
        expect(response.documents).to be_attached
        expect(response.documents.count).to eq(1)
      end

      it 'attaches document with correct filename' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: attestation_attribute)
        expect(response.documents.first.filename.to_s).to eq('attestation_fiscale_418166096.pdf')
      end

      it 'attaches document with correct content type' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: attestation_attribute)
        expect(response.documents.first.content_type).to eq('application/pdf')
      end

      it 'sets source to auto' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: attestation_attribute)
        expect(response.source).to eq('auto')
      end

      context 'when response type does not support documents' do
        let!(:text_attribute) do
          create(:market_attribute, :text_input, :from_api,
            key: 'some_text_field',
            api_name: 'Insee',
            api_key: 'attestation',
            public_markets: [public_market])
        end

        before do
          attestation_attribute.destroy
        end

        it 'succeeds without crashing' do
          expect(subject).to be_success
        end

        it 'does not crash when trying to attach document' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when response already exists with manual_after_api_failure' do
        before do
          response = MarketAttributeResponse.build_for_attribute(
            attestation_attribute,
            market_application:
          )
          response.source = :manual_after_api_failure
          response.documents.attach(
            io: StringIO.new('Manual PDF'),
            filename: 'manual_document.pdf',
            content_type: 'application/pdf'
          )
          response.save!
        end

        it 'does not change source from manual_after_api_failure' do
          subject
          response = market_application.market_attribute_responses.find_by(market_attribute: attestation_attribute)
          expect(response.source).to eq('manual_after_api_failure')
        end

        it 'still attaches the new document' do
          subject
          response = market_application.market_attribute_responses.find_by(market_attribute: attestation_attribute)
          expect(response.documents.count).to eq(2)
        end
      end
    end

    context 'when resource contains both text values and document hashes' do
      let(:document_io) { StringIO.new('PDF content') }
      let(:document_hash) do
        {
          io: document_io,
          filename: 'attestation.pdf',
          content_type: 'application/pdf',
          metadata: { source: 'api' }
        }
      end
      let(:resource) { Resource.new(siret: '41816609600069', attestation: document_hash) }

      let!(:siret_attribute) do
        create(:market_attribute, :text_input, :from_api,
          key: 'identite_entreprise_identification_siret',
          api_name: 'Insee',
          api_key: 'siret',
          public_markets: [public_market])
      end

      let!(:attestation_attribute) do
        create(:market_attribute, :file_upload, :from_api,
          key: 'fiscalite_attestations_fiscales',
          api_name: 'Insee',
          api_key: 'attestation',
          public_markets: [public_market])
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates responses for both text and document' do
        expect { subject }.to change { market_application.market_attribute_responses.count }.by(2)
      end

      it 'correctly sets text value for text attribute' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: siret_attribute)
        expect(response.text).to eq('41816609600069')
      end

      it 'correctly attaches document for document attribute' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: attestation_attribute)
        expect(response.documents).to be_attached
      end
    end

    context 'when resource contains an array of documents (cotisation_retraite)' do
      let(:cibtp_io) { StringIO.new('PDF content CIBTP') }
      let(:cnetp_io) { StringIO.new('PDF content CNETP') }

      let(:cibtp_document) do
        {
          io: cibtp_io,
          filename: 'attestation_cibtp_41816609600069.pdf',
          content_type: 'application/pdf',
          metadata: { source: 'api_cibtp', api_name: 'cibtp' }
        }
      end

      let(:cnetp_document) do
        {
          io: cnetp_io,
          filename: 'attestation_cnetp_418166096.pdf',
          content_type: 'application/pdf',
          metadata: { source: 'api_cnetp', api_name: 'cnetp' }
        }
      end

      let(:resource) { Resource.new(documents: [cibtp_document, cnetp_document]) }
      let(:api_name) { 'cotisation_retraite' }

      let!(:cotisation_retraite_attribute) do
        create(:market_attribute, :file_upload, :from_api,
          key: 'motifs_exclusion_fiscales_et_sociales_cibtp_cnetp',
          api_name: 'cotisation_retraite',
          api_key: 'documents',
          public_markets: [public_market])
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates market_attribute_response for the documents' do
        expect { subject }.to change { market_application.market_attribute_responses.count }.by(1)
      end

      it 'attaches both documents to the response' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: cotisation_retraite_attribute)
        expect(response.documents).to be_attached
        expect(response.documents.count).to eq(2)
      end

      it 'attaches CIBTP document with correct filename' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: cotisation_retraite_attribute)
        cibtp_doc = response.documents.find { |d| d.filename.to_s.include?('cibtp') }
        expect(cibtp_doc.filename.to_s).to eq('attestation_cibtp_41816609600069.pdf')
      end

      it 'attaches CNETP document with correct filename' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: cotisation_retraite_attribute)
        cnetp_doc = response.documents.find { |d| d.filename.to_s.include?('cnetp') }
        expect(cnetp_doc.filename.to_s).to eq('attestation_cnetp_418166096.pdf')
      end

      it 'sets source to auto' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: cotisation_retraite_attribute)
        expect(response.source).to eq('auto')
      end

      context 'when only CIBTP document is present' do
        let(:resource) { Resource.new(documents: [cibtp_document]) }

        it 'attaches only the CIBTP document' do
          subject
          response = market_application.market_attribute_responses.find_by(market_attribute: cotisation_retraite_attribute)
          expect(response.documents.count).to eq(1)
          expect(response.documents.first.filename.to_s).to include('cibtp')
        end
      end

      context 'when only CNETP document is present' do
        let(:resource) { Resource.new(documents: [cnetp_document]) }

        it 'attaches only the CNETP document' do
          subject
          response = market_application.market_attribute_responses.find_by(market_attribute: cotisation_retraite_attribute)
          expect(response.documents.count).to eq(1)
          expect(response.documents.first.filename.to_s).to include('cnetp')
        end
      end

      context 'when response already exists with one document and we re-attach both' do
        before do
          # First call - attach only CIBTP
          described_class.call(
            market_application:,
            api_name: 'cotisation_retraite',
            bundled_data: BundledData.new(
              data: Resource.new(documents: [cibtp_document]),
              context: {}
            )
          )
        end

        it 'replaces old CIBTP document and adds new CNETP document' do
          # Second call - attach both CIBTP (updated) and CNETP (new)
          new_cibtp_io = StringIO.new('NEW PDF content CIBTP')
          updated_cibtp_document = {
            io: new_cibtp_io,
            filename: 'attestation_cibtp_updated.pdf',
            content_type: 'application/pdf',
            metadata: { source: 'api_cibtp', api_name: 'cibtp' }
          }

          described_class.call(
            market_application:,
            api_name: 'cotisation_retraite',
            bundled_data: BundledData.new(
              data: Resource.new(documents: [updated_cibtp_document, cnetp_document]),
              context: {}
            )
          )

          response = market_application.market_attribute_responses.find_by(market_attribute: cotisation_retraite_attribute)
          expect(response.documents.count).to eq(2)

          # Verify old CIBTP was purged and new one attached
          cibtp_doc = response.documents.find { |d| d.filename.to_s.include?('cibtp') }
          expect(cibtp_doc.filename.to_s).to eq('attestation_cibtp_updated.pdf')

          # Verify CNETP was added
          cnetp_doc = response.documents.find { |d| d.filename.to_s.include?('cnetp') }
          expect(cnetp_doc).to be_present
        end
      end

      context 'when response already exists with both documents and we update one' do
        before do
          # First call - attach both documents
          described_class.call(
            market_application:,
            api_name: 'cotisation_retraite',
            bundled_data: BundledData.new(
              data: Resource.new(documents: [cibtp_document, cnetp_document]),
              context: {}
            )
          )
        end

        it 'updates only the CIBTP document, keeps CNETP unchanged' do
          # Second call - update only CIBTP
          new_cibtp_io = StringIO.new('UPDATED PDF content CIBTP')
          updated_cibtp_document = {
            io: new_cibtp_io,
            filename: 'attestation_cibtp_v2.pdf',
            content_type: 'application/pdf',
            metadata: { source: 'api_cibtp', api_name: 'cibtp' }
          }

          described_class.call(
            market_application:,
            api_name: 'cotisation_retraite',
            bundled_data: BundledData.new(
              data: Resource.new(documents: [updated_cibtp_document]),
              context: {}
            )
          )

          response = market_application.market_attribute_responses.find_by(market_attribute: cotisation_retraite_attribute)
          expect(response.documents.count).to eq(2)

          # Verify CIBTP was updated
          cibtp_doc = response.documents.find { |d| d.filename.to_s.include?('cibtp') }
          expect(cibtp_doc.filename.to_s).to eq('attestation_cibtp_v2.pdf')

          # Verify CNETP was preserved (still has original filename)
          cnetp_doc = response.documents.find { |d| d.filename.to_s.include?('cnetp') }
          expect(cnetp_doc.filename.to_s).to eq('attestation_cnetp_418166096.pdf')
        end

        it 'updates only the CNETP document, keeps CIBTP unchanged' do
          # Second call - update only CNETP
          new_cnetp_io = StringIO.new('UPDATED PDF content CNETP')
          updated_cnetp_document = {
            io: new_cnetp_io,
            filename: 'attestation_cnetp_v2.pdf',
            content_type: 'application/pdf',
            metadata: { source: 'api_cnetp', api_name: 'cnetp' }
          }

          described_class.call(
            market_application:,
            api_name: 'cotisation_retraite',
            bundled_data: BundledData.new(
              data: Resource.new(documents: [updated_cnetp_document]),
              context: {}
            )
          )

          response = market_application.market_attribute_responses.find_by(market_attribute: cotisation_retraite_attribute)
          expect(response.documents.count).to eq(2)

          # Verify CIBTP was preserved (still has original filename)
          cibtp_doc = response.documents.find { |d| d.filename.to_s.include?('cibtp') }
          expect(cibtp_doc.filename.to_s).to eq('attestation_cibtp_41816609600069.pdf')

          # Verify CNETP was updated
          cnetp_doc = response.documents.find { |d| d.filename.to_s.include?('cnetp') }
          expect(cnetp_doc.filename.to_s).to eq('attestation_cnetp_v2.pdf')
        end
      end
    end

    context 'when resource contains CARIF-OREF qualiopi metadata' do
      let(:qualiopi_data) do
        {
          'numero_de_declaration' => '11910843391',
          'actif' => true,
          'date_derniere_declaration' => '2021-01-30',
          'certification_qualiopi' => {
            'action_formation' => true,
            'bilan_competences' => true,
            'validation_acquis_experience' => false,
            'apprentissage' => true,
            'obtention_via_unite_legale' => true
          },
          'specialites' => [
            { 'code' => '313', 'libelle' => 'Finances, banque, assurances' }
          ]
        }
      end
      let(:resource) { Resource.new(qualiopi: qualiopi_data, france_competence: nil) }
      let(:bundled_data) { BundledData.new(data: resource, context: {}) }
      let(:api_name) { 'carif_oref' }

      let!(:qualiopi_attribute) do
        create(:market_attribute, :inline_file_upload, :from_api,
          key: 'capacites_techniques_professionnelles_certificats_qualiopi_france',
          api_name: 'carif_oref',
          api_key: 'qualiopi',
          public_markets: [public_market])
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates market_attribute_response for qualiopi' do
        expect { subject }.to change { market_application.market_attribute_responses.count }.by(1)
      end

      it 'stores qualiopi data in value JSONB field' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: qualiopi_attribute)
        expect(response.value['numero_de_declaration']).to eq('11910843391')
        expect(response.value['certification_qualiopi']['action_formation']).to be true
        expect(response.value['specialites'].first['libelle']).to eq('Finances, banque, assurances')
      end

      it 'sets source to auto' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: qualiopi_attribute)
        expect(response.source).to eq('auto')
      end
    end

    context 'when resource contains CARIF-OREF france_competence metadata' do
      let(:france_competence_data) do
        {
          'habilitations' => [
            {
              'code' => 'RNCP10013',
              'actif' => true,
              'date_actif' => '2020-01-30',
              'date_fin_enregistrement' => '2030-01-30',
              'habilitation_pour_former' => true,
              'habilitation_pour_organiser_l_evaluation' => true,
              'sirets_organismes_certificateurs' => ['12345678901234']
            }
          ]
        }
      end
      let(:resource) { Resource.new(qualiopi: nil, france_competence: france_competence_data) }
      let(:bundled_data) { BundledData.new(data: resource, context: {}) }
      let(:api_name) { 'carif_oref' }

      let!(:france_competence_attribute) do
        create(:market_attribute, :inline_url_input, :from_api,
          key: 'capacites_techniques_professionnelles_certificats_france_competences',
          api_name: 'carif_oref',
          api_key: 'france_competence',
          public_markets: [public_market])
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates market_attribute_response for france_competence' do
        expect { subject }.to change { market_application.market_attribute_responses.count }.by(1)
      end

      it 'stores france_competence habilitations in value JSONB field' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: france_competence_attribute)
        expect(response.value['habilitations']).to be_an(Array)
        expect(response.value['habilitations'].first['code']).to eq('RNCP10013')
        expect(response.value['habilitations'].first['actif']).to be true
      end

      it 'sets source to auto' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: france_competence_attribute)
        expect(response.source).to eq('auto')
      end
    end

    context 'when resource contains both CARIF-OREF qualiopi and france_competence' do
      let(:qualiopi_data) do
        {
          'numero_de_declaration' => '11910843391',
          'certification_qualiopi' => { 'action_formation' => true },
          'specialites' => []
        }
      end
      let(:france_competence_data) do
        {
          'habilitations' => [{ 'code' => 'RNCP10013', 'actif' => true }]
        }
      end
      let(:resource) { Resource.new(qualiopi: qualiopi_data, france_competence: france_competence_data) }
      let(:bundled_data) { BundledData.new(data: resource, context: {}) }
      let(:api_name) { 'carif_oref' }

      let!(:qualiopi_attribute) do
        create(:market_attribute, :inline_file_upload, :from_api,
          key: 'capacites_techniques_professionnelles_certificats_qualiopi_france',
          api_name: 'carif_oref',
          api_key: 'qualiopi',
          public_markets: [public_market])
      end

      let!(:france_competence_attribute) do
        create(:market_attribute, :inline_url_input, :from_api,
          key: 'capacites_techniques_professionnelles_certificats_france_competences',
          api_name: 'carif_oref',
          api_key: 'france_competence',
          public_markets: [public_market])
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates market_attribute_responses for both fields' do
        expect { subject }.to change { market_application.market_attribute_responses.count }.by(2)
      end

      it 'stores qualiopi data correctly' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: qualiopi_attribute)
        expect(response.value['numero_de_declaration']).to eq('11910843391')
      end

      it 'stores france_competence data correctly' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: france_competence_attribute)
        expect(response.value['habilitations'].first['code']).to eq('RNCP10013')
      end
    end

    context 'when CARIF-OREF returns nil data' do
      let(:resource) { Resource.new(qualiopi: nil, france_competence: nil) }
      let(:bundled_data) { BundledData.new(data: resource, context: {}) }
      let(:api_name) { 'carif_oref' }

      let!(:qualiopi_attribute) do
        create(:market_attribute, :inline_file_upload, :from_api,
          key: 'capacites_techniques_professionnelles_certificats_qualiopi_france',
          api_name: 'carif_oref',
          api_key: 'qualiopi',
          public_markets: [public_market])
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates response with empty value' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: qualiopi_attribute)
        expect(response.value).to eq({})
      end
    end

    context 'when resource contains OPQIBI metadata (api_key=data)' do
      let(:resource) do
        Resource.new(
          url: 'https://www.opqibi.com/fiche/1777',
          date_delivrance_certificat: '2021-01-28',
          duree_validite_certificat: 'valable un an'
        )
      end
      let(:bundled_data) { BundledData.new(data: resource, context: {}) }
      let(:api_name) { 'opqibi' }

      let!(:opqibi_attribute) do
        create(:market_attribute, :inline_url_input, :from_api,
          key: 'capacites_techniques_professionnelles_certificats_opqibi',
          api_name: 'opqibi',
          api_key: 'data',
          public_markets: [public_market])
      end

      it 'succeeds' do
        expect(subject).to be_success
      end

      it 'creates market_attribute_response for OPQIBI' do
        expect { subject }.to change { market_application.market_attribute_responses.count }.by(1)
      end

      it 'stores URL in text field' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: opqibi_attribute)
        expect(response.text).to eq('https://www.opqibi.com/fiche/1777')
      end

      it 'stores metadata in value JSONB field' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: opqibi_attribute)
        expect(response.value['date_delivrance_certificat']).to eq('2021-01-28')
        expect(response.value['duree_validite_certificat']).to eq('valable un an')
      end

      it 'sets source to auto' do
        subject
        response = market_application.market_attribute_responses.find_by(market_attribute: opqibi_attribute)
        expect(response.source).to eq('auto')
      end

      context 'when response already exists' do
        before do
          response = MarketAttributeResponse.build_for_attribute(
            opqibi_attribute,
            market_application:
          )
          response.value = {
            'text' => 'https://www.opqibi.com/fiche/old',
            'date_delivrance_certificat' => '2020-01-01',
            'duree_validite_certificat' => 'old'
          }
          response.source = :auto
          response.save!
        end

        it 'updates existing response instead of creating new one' do
          expect { subject }.not_to change { market_application.market_attribute_responses.count }
        end

        it 'updates the URL in text field' do
          subject
          response = market_application.market_attribute_responses.find_by(market_attribute: opqibi_attribute)
          expect(response.text).to eq('https://www.opqibi.com/fiche/1777')
        end

        it 'updates the metadata in value field' do
          subject
          response = market_application.market_attribute_responses.find_by(market_attribute: opqibi_attribute)
          expect(response.value['date_delivrance_certificat']).to eq('2021-01-28')
          expect(response.value['duree_validite_certificat']).to eq('valable un an')
        end
      end
    end
  end
end
