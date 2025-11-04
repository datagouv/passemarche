# frozen_string_literal: true

module Candidate
  class DeleteUnattachedBlob < ApplicationInteractor
    delegate :signed_id, to: :context

    def call
      find_blob
      attached?
      purge_blob
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      context.fail!(message: 'invalid_signature')
    end

    private

    def find_blob
      context.blob = ActiveStorage::Blob.find_signed!(signed_id)
    rescue ActiveRecord::RecordNotFound
      context.fail!(message: 'not_found')
    end

    def attached?
      context.is_attached = context.blob.attachments.exists?
    end

    def purge_blob
      return if context.is_attached
      return if context.deleted

      context.blob.purge_later
      context.deleted = true
    end
  end
end
