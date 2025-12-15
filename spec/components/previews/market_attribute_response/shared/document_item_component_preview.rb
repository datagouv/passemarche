# frozen_string_literal: true

# @label Document Item
# @logical_path market_attribute_response/shared
module MarketAttributeResponse
  module Shared
    class DocumentItemComponentPreview < Lookbook::Preview
      # @label PDF Document
      # @display bg_color "#f6f6f6"
      def pdf_document
        document = create_or_find_document('document_example.pdf', 'application/pdf', 1024)
        market_application = find_or_create_market_application

        render DocumentItemComponent.new(
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

        render DocumentItemComponent.new(
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

        render DocumentItemComponent.new(
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

        render DocumentItemComponent.new(
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

        render DocumentItemComponent.new(
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
          public_market:
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

      def create_or_find_document(filename, content_type, byte_size)
        existing = ActiveStorage::Blob.find_by(filename:)
        return existing if existing

        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new('x' * byte_size),
          filename:,
          content_type:
        )
      end
    end
  end
end
