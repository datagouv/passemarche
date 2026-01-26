# frozen_string_literal: true

class MarketAttributeResponse::Fields::FileUploadFieldComponent < ViewComponent::Base
  attr_reader :form, :attribute_response, :deletable, :label, :multiple, :show_security_badge

  def initialize(form:, attribute_response:, **options)
    @form = form
    @attribute_response = attribute_response
    @deletable = options.fetch(:deletable, true)
    @label = options.fetch(:label, nil)
    @multiple = options.fetch(:multiple, true)
    @show_security_badge = options.fetch(:show_security_badge, false)
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
    relevant_errors.present?
  end

  def base_error_message
    relevant_errors.first
  end

  def documents_errors?
    attribute_response.errors[:documents].present?
  end

  def documents_error_messages
    attribute_response.errors[:documents]
  end

  private

  def relevant_errors
    return [] if form.object.errors[:base].blank?

    current_filenames = documents.map { |d| d.filename.to_s }

    form.object.errors[:base].select do |error_msg|
      error_relevant_for_file?(error_msg, current_filenames)
    end
  end

  def error_relevant_for_file?(error_msg, current_filenames)
    # Keep errors that don't mention specific files
    return true unless error_msg.include?(':')

    mentioned_file = extract_filename_from_error(error_msg)
    current_filenames.include?(mentioned_file)
  end

  def extract_filename_from_error(error_msg)
    error_msg.split(':').first.strip
  end

  def empty_state_message
    'Aucun fichier téléchargé'
  end
end
