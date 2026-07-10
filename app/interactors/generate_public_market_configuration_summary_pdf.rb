# frozen_string_literal: true

class GeneratePublicMarketConfigurationSummaryPdf < ApplicationInteractor
  include PdfGeneratable

  delegate :public_market, to: :context

  def call
    generate_and_attach_pdf(
      attachment: public_market.configuration_summary,
      template: 'buyer/public_markets/configuration_summary',
      locals: { public_market:, presenter: PublicMarketPresenter.new(public_market), transmission_time: },
      filename:
    )
    context.configuration_summary = public_market.configuration_summary
  end

  private

  def transmission_time
    @transmission_time ||= Time.zone.now.strftime('%d/%m/%Y à %H:%M')
  end

  def filename
    "configuration_summary_#{public_market.identifier}.pdf"
  end

  def pdf_error_message
    "Failed to generate configuration summary PDF for market #{public_market.identifier}"
  end

  def pdf_sentry_extra
    {
      public_market_id: public_market.id,
      public_market_identifier: public_market.identifier
    }
  end

  def pdf_error_stage
    'configuration_summary_pdf_generation'
  end

  def pdf_document_type
    'configuration_summary'
  end

  def pdf_failure_i18n_message
    I18n.t('errors.public_market.configuration_summary_generation_failed')
  end
end
