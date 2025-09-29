module Candidate
  class DocumentsController < ApplicationController
    before_action :find_market_application

    def destroy
      authorized_document_ids = @market_application
        .market_attribute_responses
        .where(type: %w[FileUpload CheckboxWithDocument FileOrTextarea])
        .includes(:documents_attachments)
        .flat_map { |resp| resp.documents_attachments.pluck(:id) }

      document = ActiveStorage::Attachment
        .where(id: authorized_document_ids)
        .find_by(id: params[:id])

      if document.blank?
        render plain: 'Document non trouvé ou non autorisé', status: :not_found
      else
        document.purge

        render plain: 'Document supprimé avec succès', status: :ok
      end
    end

    private

    def find_market_application
      @market_application = MarketApplication.find_by!(identifier: params[:market_application_identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: 'La candidature recherchée n\'a pas été trouvé', status: :not_found
    end
  end
end
