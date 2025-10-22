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

  # rubocop:disable Metrics/ParameterLists
  def current_documents_list(documents, market_application_identifier: nil, show_empty: false, deletable: false, form: nil, field_name: :files)
    # rubocop:enable Metrics/ParameterLists
    persisted_documents = documents.select(&:persisted?)

    if persisted_documents.any?
      render_documents_list(persisted_documents, market_application_identifier, deletable, form, field_name)
    elsif show_empty
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

  # rubocop:disable Metrics/ParameterLists
  def direct_upload_field(documents: nil, market_application_identifier: nil, show_empty: false,
                          deletable: false, wrapper_class: '', form: nil, field_name: :files, &)
    # rubocop:enable Metrics/ParameterLists
    content_tag :div, class: "fr-upload-group #{wrapper_class}".strip,
      data: {
        controller: 'direct-upload',
        direct_upload_market_application_identifier_value: market_application_identifier,
        direct_upload_deletable_value: deletable
      } do
      concat capture(&)
      concat render('candidate/market_applications/market_attribute_responses/shared/progress_bar')

      files_content = if documents
                        current_documents_list(documents,
                          market_application_identifier:,
                          show_empty:,
                          deletable:,
                          form:,
                          field_name:)
                      elsif show_empty
                        render_empty_documents_list
                      else
                        ''.html_safe
                      end

      concat content_tag(:div, files_content, class: 'files-list', data: { direct_upload_target: 'filesList' })
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

  def render_documents_list(persisted_documents, market_application_identifier, deletable, form, field_name)
    content_tag :div, class: 'fr-mt-2w fr-text--sm fr-mb-0' do
      concat content_tag(:strong, 'Documents actuels :')
      persisted_documents.each do |document|
        # Add hidden field to preserve file on form resubmit (backend now handles duplicates)
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
    content_tag :div, class: 'fr-mt-2w fr-text--sm fr-mb-0' do
      concat content_tag(:strong, 'Fichiers actuels :')
      concat content_tag(:span, 'Aucun fichier téléchargé')
    end
  end
end
