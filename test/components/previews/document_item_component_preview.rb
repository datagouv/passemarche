# frozen_string_literal: true

# @label Document Item
# @logical_path market_attribute_response/shared
class DocumentItemComponentPreview < ViewComponent::Preview
  # @label PDF Document
  # @display bg_color "#f6f6f6"
  def pdf_document
    attachment = create_or_find_attachment('document_example.pdf', 'application/pdf', 1024)
    market_application = attachment.record.market_application

    render MarketAttributeResponse::Shared::DocumentItemComponent.new(
      document: attachment,
      market_application:,
      context: :web
    )
  end

  # @label Image Document
  # @display bg_color "#f6f6f6"
  def image_document
    attachment = create_or_find_attachment('photo_example.jpg', 'image/jpeg', 2048)
    market_application = attachment.record.market_application

    render MarketAttributeResponse::Shared::DocumentItemComponent.new(
      document: attachment,
      market_application:,
      context: :web
    )
  end

  # @label Long Filename
  # @display bg_color "#f6f6f6"
  def long_filename
    attachment = create_or_find_attachment(
      'very_long_document_name_that_might_need_truncation_in_some_cases.pdf',
      'application/pdf',
      512
    )
    market_application = attachment.record.market_application

    render MarketAttributeResponse::Shared::DocumentItemComponent.new(
      document: attachment,
      market_application:,
      context: :web
    )
  end

  # @label Without Size
  # @display bg_color "#f6f6f6"
  def without_size
    attachment = create_or_find_attachment('document_no_size.pdf', 'application/pdf', 4096)
    market_application = attachment.record.market_application

    render MarketAttributeResponse::Shared::DocumentItemComponent.new(
      document: attachment,
      market_application:,
      context: :web,
      show_size: false
    )
  end

  # @label Buyer Context (System Name)
  # @display bg_color "#f6f6f6"
  def buyer_context
    attachment = create_or_find_attachment('original_document.pdf', 'application/pdf', 1024)
    market_application = attachment.record.market_application

    render MarketAttributeResponse::Shared::DocumentItemComponent.new(
      document: attachment,
      market_application:,
      context: :buyer
    )
  end

  private

  def create_or_find_attachment(filename, content_type, byte_size)
    # Find existing response with this document attached
    existing_blob = ActiveStorage::Blob.find_by(filename:)
    if existing_blob
      attachment = ActiveStorage::Attachment.find_by(blob_id: existing_blob.id)
      return attachment if attachment
    end

    # Create a new response with the document attached
    response = find_or_create_file_upload_response
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new('x' * byte_size),
      filename:,
      content_type:
    )
    response.documents.attach(blob)
    response.documents.find_by(blob_id: blob.id)
  end

  def find_or_create_file_upload_response
    market_application = find_or_create_market_application
    market_attribute = find_or_create_file_upload_attribute

    MarketAttributeResponse::FileUpload.find_or_create_by!(
      market_application:,
      market_attribute:
    ) do |response|
      response.source = :manual
    end
  end

  def find_or_create_market_application
    MarketApplication.find_by(identifier: 'preview-document-item') || create_market_application
  end

  def create_market_application
    public_market = PublicMarket.first || create_public_market
    MarketApplication.create!(
      identifier: 'preview-document-item',
      public_market:,
      siret: '73282932000074',
      attests_no_exclusion_motifs: true
    )
  end

  def create_public_market
    editor = Editor.first || Editor.create!(
      name: 'Preview Editor',
      oauth_application_uid: 'preview-uid'
    )
    PublicMarket.create!(
      identifier: 'preview-market',
      editor:
    )
  end

  def find_or_create_file_upload_attribute
    MarketAttribute.find_or_create_by!(key: 'preview_document_item') do |attr|
      attr.input_type = :file_upload
      attr.category_key = 'documents'
      attr.subcategory_key = 'general'
      attr.mandatory = false
    end
  end
end
