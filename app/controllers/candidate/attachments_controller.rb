# frozen_string_literal: true

module Candidate
  class AttachmentsController < ApplicationController
    before_action :find_market_application
    before_action :find_attachment

    def destroy
      if @attachment && attachment_belongs_to_application?
        @attachment.purge_later
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
      render json: { success: false, message: 'Application not found' }, status: :not_found
    end

    def find_attachment
      @attachment = ActiveStorage::Attachment.find_by(
        blob: ActiveStorage::Blob.find_signed(params[:signed_id])
      )
    end

    def attachment_belongs_to_application?
      return false unless @attachment

      # Check if the attachment's record is a MarketAttributeResponse belonging to this application
      @attachment.record_type == 'MarketAttributeResponse' &&
        @market_application.market_attribute_responses.exists?(id: @attachment.record_id)
    end
  end
end
