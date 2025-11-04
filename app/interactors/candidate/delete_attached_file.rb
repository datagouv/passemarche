# frozen_string_literal: true

module Candidate
  class DeleteAttachedFile < ApplicationInteractor
    delegate :signed_id, :market_application, to: :context

    def call
      find_blob
      find_attachment
      validate_attachment_ownership
      delete_attachment
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      context.fail!(message: 'invalid_signature')
    end

    private

    def find_blob
      context.blob = ActiveStorage::Blob.find_signed!(signed_id)
    rescue ActiveRecord::RecordNotFound
      context.fail!(message: 'not_found')
    end

    def find_attachment
      context.attachment = ActiveStorage::Attachment.find_by(blob: context.blob)
    end

    def validate_attachment_ownership
      return unless context.attachment
      return if attachment_belongs_to_application?

      context.fail!(message: 'not_found')
    end

    def attachment_belongs_to_application?
      context.attachment.record_type == 'MarketAttributeResponse' &&
        market_application.market_attribute_responses.exists?(id: context.attachment.record_id)
    end

    def delete_attachment
      return unless context.attachment

      context.attachment.purge_later
      context.deleted = true
    end
  end
end
