# frozen_string_literal: true

module PdfGeneratable
  extend ActiveSupport::Concern

  WICKED_PDF_OPTIONS = {
    page_size: 'A4',
    margin: {
      top: 20,
      bottom: 20,
      left: 15,
      right: 15
    },
    print_media_type: true
  }.freeze

  private

  def generate_and_attach_pdf(attachment:, template:, locals:, filename:)
    pdf_content = render_and_watermark_pdf(template:, locals:)
    attach_pdf(attachment:, pdf_content:, filename:)
  rescue ActionView::Template::Error,
         ActionView::MissingTemplate,
         ActiveStorage::Error,
         Errno::ENOENT, Errno::EACCES,
         RuntimeError => e
    handle_pdf_generation_error(e)
  end

  def render_and_watermark_pdf(template:, locals:)
    html_content = ApplicationController.render(template:, formats: [:html], layout: false, locals:)
    pdf_content = WickedPdf.new.pdf_from_string(html_content, **WICKED_PDF_OPTIONS)

    PdfWatermarkService.call(pdf_content)
  end

  def attach_pdf(attachment:, pdf_content:, filename:)
    attachment.attach(io: StringIO.new(pdf_content), filename:, content_type: 'application/pdf')
  end

  def handle_pdf_generation_error(error)
    Rails.logger.error "#{pdf_error_message}: #{error.class} - #{error.message}"
    Rails.logger.error error.backtrace.first(10).join("\n")

    Sentry.capture_exception(error, extra: sentry_extra(error), tags: sentry_tags)

    context.fail!(message: pdf_failure_i18n_message)
  end

  def sentry_extra(error)
    pdf_sentry_extra.merge(
      error_stage: pdf_error_stage,
      error_class: error.class.name,
      error_message: error.message
    )
  end

  def sentry_tags
    {
      component: 'pdf_generation',
      document_type: pdf_document_type
    }
  end
end
