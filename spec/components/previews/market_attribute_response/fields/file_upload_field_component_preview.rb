# frozen_string_literal: true

# @label File Upload Field
# @logical_path market_attribute_response/fields
module MarketAttributeResponse
  module Fields
    class FileUploadFieldComponentPreview < Lookbook::Preview
      # @label Empty (No Files)
      # @display bg_color "#f6f6f6"
      def empty
        response = create_response_without_files
        form = form_builder_for(response)

        render FileUploadFieldComponent.new(
          form:,
          attribute_response: response
        )
      end

      # @label With Files Attached
      # @display bg_color "#f6f6f6"
      def with_files
        response = create_response_with_files
        form = form_builder_for(response)

        render FileUploadFieldComponent.new(
          form:,
          attribute_response: response
        )
      end

      # @label Custom Label
      # @display bg_color "#f6f6f6"
      def custom_label
        response = create_response_without_files
        form = form_builder_for(response)

        render FileUploadFieldComponent.new(
          form:,
          attribute_response: response,
          label: 'Télécharger votre justificatif'
        )
      end

      # @label Not Deletable
      # @display bg_color "#f6f6f6"
      def not_deletable
        response = create_response_with_files
        form = form_builder_for(response)

        render FileUploadFieldComponent.new(
          form:,
          attribute_response: response,
          deletable: false
        )
      end

      # @label Single File Only
      # @display bg_color "#f6f6f6"
      def single_file
        response = create_response_without_files
        form = form_builder_for(response)

        render FileUploadFieldComponent.new(
          form:,
          attribute_response: response,
          multiple: false,
          label: 'Ajouter un document'
        )
      end

      # @label With Validation Error
      # @display bg_color "#f6f6f6"
      def with_error
        response = create_response_without_files
        response.errors.add(:base, 'Le fichier est trop volumineux')
        form = form_builder_for(response)

        render FileUploadFieldComponent.new(
          form:,
          attribute_response: response
        )
      end

      private

      def create_response_without_files
        market_application = find_or_create_market_application
        market_attribute = find_or_create_market_attribute

        MarketAttributeResponse::FileUpload.find_or_create_by!(
          market_application:,
          market_attribute:
        ) do |response|
          response.source = :manual
        end
      end

      def create_response_with_files
        response = create_response_without_files
        attach_sample_file(response) unless response.documents.attached?
        response
      end

      def attach_sample_file(response)
        blob = ActiveStorage::Blob.find_by(filename: 'preview_document.pdf') ||
               ActiveStorage::Blob.create_and_upload!(
                 io: StringIO.new('Sample PDF content'),
                 filename: 'preview_document.pdf',
                 content_type: 'application/pdf'
               )
        response.documents.attach(blob) unless response.documents.blobs.include?(blob)
      end

      def find_or_create_market_application
        MarketApplication.first || create_market_application
      end

      def create_market_application
        public_market = PublicMarket.first || create_public_market
        MarketApplication.create!(
          identifier: 'preview-file-upload',
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

      def find_or_create_market_attribute
        MarketAttribute.find_by(key: 'preview_file_upload') ||
          MarketAttribute.create!(
            key: 'preview_file_upload',
            input_type: :file_upload,
            category_key: 'capacites_techniques_professionnelles',
            subcategory_key: 'certificats_qualite',
            mandatory: false
          )
      end

      def form_builder_for(response)
        template = ActionView::Base.empty
        template.output_buffer = ActiveSupport::SafeBuffer.new

        ActionView::Helpers::FormBuilder.new(
          :market_attribute_response,
          response,
          template,
          {}
        )
      end
    end
  end
end
