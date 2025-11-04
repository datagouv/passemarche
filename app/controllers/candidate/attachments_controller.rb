# frozen_string_literal: true

module Candidate
  class AttachmentsController < ApplicationController
    before_action :find_market_application

    def destroy
      result = Candidate::DeleteFile.call(
        signed_id: params[:signed_id],
        market_application: @market_application
      )

      if result.success?
        render json: { success: true, message: I18n.t('candidate.attachments.delete_success') }
      else
        render json: { success: false, message: I18n.t('candidate.attachments.not_found') },
          status: :not_found
      end
    end

    private

    def find_market_application
      @market_application = MarketApplication.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render json: { success: false, message: I18n.t('candidate.attachments.application_not_found') },
        status: :not_found
    end
  end
end
