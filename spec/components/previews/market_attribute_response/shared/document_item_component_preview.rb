# frozen_string_literal: true

# @label Document Item
# @logical_path market_attribute_response/shared
class MarketAttributeResponse::Shared::DocumentItemComponentPreview < Lookbook::Preview
  # @label PDF Document
  # @display bg_color "#f6f6f6"
  def pdf_document
    document = create_or_find_document('document_example.pdf', 'application/pdf', 1024)
    market_application = find_or_create_market_application

    render MarketAttributeResponse::Shared::DocumentItemComponent.new(
      document:,
      market_application:,
      context: :web
    )
  end

  # @label Image Document
  # @display bg_color "#f6f6f6"
  def image_document
    document = create_or_find_document('photo_example.jpg', 'image/jpeg', 2048)
    market_application = find_or_create_market_application

    render MarketAttributeResponse::Shared::DocumentItemComponent.new(
      document:,
      market_application:,
      context: :web
    )
  end

  # @label Long Filename
  # @display bg_color "#f6f6f6"
  def long_filename
    document = create_or_find_document(
      'very_long_document_name_that_might_need_truncation_in_some_cases.pdf',
      'application/pdf',
      512
    )
    market_application = find_or_create_market_application

    render MarketAttributeResponse::Shared::DocumentItemComponent.new(
      document:,
      market_application:,
      context: :web
    )
  end

  # @label Without Size
  # @display bg_color "#f6f6f6"
  def without_size
    document = create_or_find_document('document_no_size.pdf', 'application/pdf', 4096)
    market_application = find_or_create_market_application

    render MarketAttributeResponse::Shared::DocumentItemComponent.new(
      document:,
      market_application:,
      context: :web,
      show_size: false
    )
  end

  # @label Buyer Context (System Name)
  # @display bg_color "#f6f6f6"
  def buyer_context
    document = create_or_find_document('original_document.pdf', 'application/pdf', 1024)
    market_application = find_or_create_market_application

    render MarketAttributeResponse::Shared::DocumentItemComponent.new(
      document:,
      market_application:,
      context: :buyer
    )
  end

  private

  def find_or_create_market_application
    MarketApplication.first || create_market_application
  end

  def create_market_application
    public_market = PublicMarket.first || create_public_market
    MarketApplication.create!(
      identifier: 'preview-document-item',
      public_market:,
      siret: '73282932000074',
      attests_no_exclusion_motifs: false
    )
  end

  def create_public_market
    editor = Editor.first || Editor.create!(
      name: 'Preview Editor'
    )
    PublicMarket.create!(
      identifier: 'preview-market',
      editor:,
      name: 'Marché de preview',
      deadline: 1.month.from_now,
      siret: '73282932000074',
      market_type_codes: [MarketType.find_or_create_by(code: 'works', deleted_at: nil).code],
      completed_at: Time.zone.now,
      sync_status: :sync_completed
    )
  end

  def create_or_find_document(filename, content_type, byte_size)
    response = find_or_create_file_response(filename)
    existing = response.documents.find { |doc| doc.filename.to_s == filename }
    return existing if existing

    response.documents.attach(
      io: StringIO.new('x' * byte_size),
      filename:,
      content_type:
    )
    response.documents.reload.find { |doc| doc.filename.to_s == filename }
  end

  def find_or_create_file_response(filename)
    market_application = find_or_create_market_application
    market_attribute = MarketAttribute.find_or_initialize_by(key: "preview_document_item_#{filename.parameterize}") do |attr|
      attr.input_type = :file_upload
      attr.category_key = 'capacites_techniques_professionnelles'
      attr.subcategory_key = 'certificats_qualite'
      attr.mandatory = false
    end
    market_attribute.save! unless market_attribute.persisted?

    MarketAttributeResponse::FileUpload.find_or_create_by!(market_application:, market_attribute:) do |r|
      r.source = :manual
    end
  end
end
