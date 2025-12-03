# frozen_string_literal: true

module MarketAttributeResponsesHelper
  def auto_filled_field_display(form, market_attribute_response)
    form.fields_for :market_attribute_responses, market_attribute_response,
      child_index: market_attribute_response.id do |response_form|
      concat response_hidden_fields(response_form)
    end

    auto_filled_field_content(market_attribute_response)
  end

  def response_hidden_fields(form)
    safe_join([
      form.hidden_field(:id),
      form.hidden_field(:market_attribute_id),
      form.hidden_field(:type)
    ])
  end

  def field_label(market_attribute_response)
    t("form_fields.candidate.fields.#{market_attribute_response.market_attribute.key}.name",
      default: market_attribute_response.market_attribute.key.humanize)
  end

  def field_description(market_attribute_response)
    t("form_fields.candidate.fields.#{market_attribute_response.market_attribute.key}.description",
      default: nil)
  end

  def file_upload_hint_text(max_size_class)
    max_size_mb = max_size_class / 1.megabyte
    "Taille maximale : #{max_size_mb} Mo. Formats supportés : jpg, png, pdf. Plusieurs fichiers possibles."
  end

  def document_display_name(document, market_application:, context:, naming_service: nil)
    naming_service ||= DocumentNamingService.new(market_application)
    original = naming_service.original_filename_for(document)
    system_name = naming_service.system_filename_for(document)

    return system_name if context == :buyer

    t('helpers.market_attribute_responses.document_display_name', original:, system: system_name)
  end

  def current_documents_list(documents, **options)
    persisted_documents = documents.select(&:persisted?)

    if persisted_documents.any?
      render_documents_list(persisted_documents, options)
    elsif options.fetch(:show_empty, false)
      render_empty_documents_list
    end
  end

  def nested_form_delete_button(entity_name)
    button_tag type: 'button',
      class: 'fr-btn fr-btn--secondary fr-btn--sm fr-icon-delete-line fr-btn--icon-left',
      data: { action: 'nested-form#remove' },
      title: "Supprimer #{entity_name}" do
      "Supprimer #{entity_name}"
    end
  end

  def direct_upload_field(**options, &)
    content_tag :div, class: direct_upload_wrapper_class(options),
      data: direct_upload_data_attributes(options) do
      concat capture(&)
      concat render('candidate/market_applications/market_attribute_responses/shared/progress_bar')
      concat content_tag(:div, direct_upload_files_content(options), class: 'files-list', data: { direct_upload_target: 'filesList' })
    end
  end

  private

  def auto_filled_field_content(market_attribute_response)
    content_tag :div, class: 'fr-mb-2w' do
      concat auto_filled_field_label(market_attribute_response)
      concat auto_filled_field_message
    end
  end

  def auto_filled_field_label(market_attribute_response)
    content_tag(:label, class: 'fr-label') do
      concat field_label(market_attribute_response)
      concat render('candidate/market_applications/market_attribute_responses/source_badge',
        market_attribute_response:)
    end
  end

  def auto_filled_field_message
    content_tag(:p, t('candidate.market_applications.auto_filled_message'),
      class: 'fr-text--sm fr-text--mention-grey')
  end

  def direct_upload_wrapper_class(options)
    "fr-upload-group #{options.fetch(:wrapper_class, '')}".strip
  end

  def direct_upload_data_attributes(options)
    {
      controller: 'direct-upload',
      direct_upload_market_application_identifier_value: options[:market_application_identifier],
      direct_upload_deletable_value: options.fetch(:deletable, false)
    }
  end

  def direct_upload_files_content(options)
    documents = options[:documents]
    show_empty = options.fetch(:show_empty, false)

    if documents
      current_documents_list(documents, **options)
    elsif show_empty
      render_empty_documents_list
    else
      ''.html_safe
    end
  end

  def render_documents_list(persisted_documents, options)
    form = options[:form]
    field_name = options.fetch(:field_name, :files)
    deletable = options.fetch(:deletable, false)
    market_application_identifier = options[:market_application_identifier]

    content_tag :div, class: 'fr-mt-2w fr-text--sm fr-mb-0' do
      concat content_tag(:strong, 'Documents actuels :')
      persisted_documents.each do |document|
        concat form.hidden_field(field_name, multiple: true, value: document.signed_id, id: nil) if form

        if deletable && market_application_identifier
          concat render_document_with_delete(document, market_application_identifier)
        else
          concat render_document_link(document)
        end
      end
    end
  end

  def render_document_link(document)
    content_tag(:div, link_to(document.filename.to_s, url_for(document),
      target: '_blank', rel: 'noopener'))
  end

  def render_document_with_delete(document, market_application_identifier)
    content_tag :div, class: 'file-item' do
      concat link_to(document.filename.to_s, url_for(document),
        target: '_blank', rel: 'noopener', class: 'file-link')

      delete_button = button_tag type: 'button',
        class: 'fr-btn fr-btn--tertiary-no-outline fr-btn--sm fr-icon-delete-line',
        data: {
          controller: 'file-delete',
          file_delete_signed_id_value: document.signed_id,
          file_delete_url_value: delete_attachment_candidate_market_application_path(
            market_application_identifier,
            document.signed_id
          ),
          file_delete_filename_value: document.filename.to_s,
          action: 'click->file-delete#delete'
        },
        title: "Supprimer #{document.filename}" do
        'Supprimer'
      end

      concat content_tag(:span, delete_button, class: 'file-delete-wrapper')
    end
  end

  def render_empty_documents_list
    content_tag :div, class: 'fr-mt-2w fr-text--md fr-mb-0' do
      concat content_tag(:strong, 'Fichiers actuels :')
      concat content_tag(:span, 'Aucun fichier téléchargé', class: 'fr-text-md fr-text--mention-grey')
    end
  end
end
