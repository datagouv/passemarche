# frozen_string_literal: true

class MarketAttributeResponse::Fields::FileUploadFieldComponent < ViewComponent::Base
  attr_reader :form, :attribute_response, :deletable, :label, :multiple

  def initialize(form:, attribute_response:, deletable: true, label: nil, multiple: true)
    @form = form
    @attribute_response = attribute_response
    @deletable = deletable
    @label = label
    @multiple = multiple
  end

  delegate :documents, to: :attribute_response

  delegate :attached?, to: :documents, prefix: true

  def market_application_identifier
    attribute_response.market_application&.identifier
  end

  def field_id
    "upload-#{attribute_response.id}"
  end

  def messages_id
    "#{field_id}-messages"
  end

  def label_text
    label || 'Ajouter vos documents'
  end

  def hint_text
    max_size_mb = MarketAttributeResponse::FileUpload::MAX_FILE_SIZE / 1.megabyte
    "Taille maximale : #{max_size_mb} Mo. Formats supportés : jpg, png, pdf. Plusieurs fichiers possibles."
  end

  def accepted_formats
    '.pdf,.doc,.docx,.jpg,.jpeg,.png'
  end

  def delete_attachment_path(document)
    helpers.delete_attachment_candidate_market_application_path(
      market_application_identifier,
      document.signed_id
    )
  end

  def delete_confirm_message
    I18n.t('candidate.attachments.delete_confirm')
  end

  def delete_error_message
    I18n.t('candidate.attachments.delete_error')
  end

  def network_error_message
    I18n.t('candidate.attachments.network_error')
  end

  def base_errors?
    form.object.errors[:base].present?
  end

  def base_error_message
    form.object.errors[:base].first
  end
end
