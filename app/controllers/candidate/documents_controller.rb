module Candidate
  class DocumentsController < ApplicationController
    before_action :find_market_application

    def destroy
      document = @market_application.find_authorized_document(params[:id])

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
      render plain: 'La candidature recherchée n\'a pas été trouvée', status: :not_found
    end
  end
end
