require 'rails_helper'

RSpec.describe 'Candidate::Documents', type: :request do
  let(:market_application) { create(:market_application, identifier: 'test-app') }
  let(:market_attribute_response) do
    build(:market_attribute_response_file_upload, market_application:)
  end

  let(:file) do
    tempfile = Tempfile.new(['test', '.pdf'])
    tempfile.write('%PDF-1.4 test pdf')
    tempfile.rewind
    Rack::Test::UploadedFile.new(tempfile.path, 'application/pdf')
  end

  before do
    market_attribute_response.documents.attach(file)
    market_attribute_response.save!
  end

  let(:document) { market_attribute_response.documents_attachments.first }

  describe 'DELETE /candidate/market_applications/:market_application_identifier/documents/:id' do
    context 'when the document is authorized' do
      it 'deletes the document and returns success' do
        expect do
          delete candidate_market_application_document_path(market_application.identifier, document.id)
        end.to change { ActiveStorage::Attachment.count }.by(-1)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Document supprimé avec succès')
      end
    end

    context 'when the document is not authorized' do
      let(:other_market_attribute_response) { build(:market_attribute_response_file_upload) }
      let(:other_file) do
        tempfile = Tempfile.new(['other', '.pdf'])
        tempfile.write('%PDF-1.4 other pdf')
        tempfile.rewind
        Rack::Test::UploadedFile.new(tempfile.path, 'application/pdf')
      end
      before do
        other_market_attribute_response.documents.attach(other_file)
        other_market_attribute_response.save!
      end
      let(:other_document) { other_market_attribute_response.documents_attachments.first }

      it 'returns not found' do
        delete candidate_market_application_document_path(market_application.identifier, other_document.id)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include('Document non trouvé ou non autorisé')
      end
    end

    context 'when the market application does not exist' do
      it 'returns not found' do
        delete candidate_market_application_document_path('wrong-id', document.id)
        expect(response).to have_http_status(:not_found)
        expect(response.body).to include("La candidature recherchée n'a pas été trouvé")
      end
    end
  end
end
