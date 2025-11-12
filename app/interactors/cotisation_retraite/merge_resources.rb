# frozen_string_literal: true

class CotisationRetraite::MergeResources < ApplicationInteractor
  def call
    validate_context
    return if context.failure?

    merge_documents
  end

  private

  def validate_context
    return if context.bundled_data.present?

    context.fail!(error: 'Missing bundled_data')
  end

  def merge_documents
    cibtp_doc = safe_get_document(:cibtp_document)
    cnetp_doc = safe_get_document(:cnetp_document)

    documents = build_documents_array(cibtp_doc, cnetp_doc)

    if documents.empty?
      context.fail!(error: 'Both CIBTP and CNETP APIs failed to return documents')
      return
    end

    status = determine_status(cibtp_doc, cnetp_doc)

    context.bundled_data = BundledData.new(
      data: Resource.new(documents:),
      context: { status: }
    )
  end

  def safe_get_document(key)
    data = context.bundled_data&.data
    return nil unless data.respond_to?(key)

    data.public_send(key)
  rescue NoMethodError
    nil
  end

  def build_documents_array(cibtp_doc, cnetp_doc)
    documents = []

    documents << cibtp_doc if cibtp_doc.present?
    documents << cnetp_doc if cnetp_doc.present?

    documents
  end

  def determine_status(cibtp_doc, cnetp_doc)
    if cibtp_doc.present? && cnetp_doc.present?
      'success_both'
    elsif cibtp_doc.present? || cnetp_doc.present?
      'success_partial'
    else
      'failure_both'
    end
  end
end
