# frozen_string_literal: true

require 'combine_pdf'

class PdfWatermarkService < ApplicationService
  A4_WIDTH = 595
  A4_HEIGHT = 842
  FONT_SIZE = 50
  ANGLE_DEG = -35.0

  HELVETICA_WIDTHS = {
    ' ' => 278, 'A' => 667, 'a' => 556, 'd' => 556, 'e' => 556,
    'i' => 222, 'n' => 556, 'o' => 556, 's' => 500, 't' => 278
  }.freeze

  def initialize(pdf_content, text: I18n.t('shared.pdf_environment_indicator.watermark'))
    @pdf_content = pdf_content
    @text = text
  end

  def call
    return @pdf_content if Rails.env.production?

    watermark = create_watermark_page
    pdf = CombinePDF.parse(@pdf_content)
    pdf.pages.each { |page| page << watermark }
    pdf.to_pdf
  rescue CombinePDF::ParsingError
    @pdf_content
  end

  private

  def create_watermark_page
    page = CombinePDF.create_page([0, 0, A4_WIDTH, A4_HEIGHT])

    page[:Contents][:referenced_object][:raw_stream_content] = watermark_stream
    page[:Resources] ||= {}
    page[:Resources][:Font] = { F1: { Type: :Font, Subtype: :Type1, BaseFont: :Helvetica } }

    page
  end

  def watermark_stream
    cos, sin, tx, ty = rotation_params

    # rubocop:disable Style/FormatStringToken
    tm_line = format('%.4f %.4f %.4f %.4f %.4f %.4f Tm', cos, sin, -sin, cos, tx, ty)
    # rubocop:enable Style/FormatStringToken

    "q\n0.8 0.8 0.8 rg\nBT\n/F1 #{FONT_SIZE} Tf\n#{tm_line}\n(#{pdf_escape(@text)}) Tj\nET\nQ\n"
  end

  # rubocop:disable Metrics/AbcSize
  def rotation_params
    angle = ANGLE_DEG * Math::PI / 180.0
    cos = Math.cos(angle)
    sin = Math.sin(angle)

    text_width = helvetica_width(@text, FONT_SIZE)
    baseline_offset = FONT_SIZE * 0.36
    cx = A4_WIDTH / 2.0
    cy = A4_HEIGHT / 2.0
    tx = cx - ((text_width / 2.0) * cos) + (baseline_offset * sin)
    ty = cy - ((text_width / 2.0) * sin) - (baseline_offset * cos)

    [cos, sin, tx, ty]
  end
  # rubocop:enable Metrics/AbcSize

  def helvetica_width(text, size)
    text.chars.sum { |c| HELVETICA_WIDTHS.fetch(c, 500) } * size / 1000.0
  end

  def pdf_escape(text)
    text.gsub('\\', '\\\\\\\\').gsub('(', '\\(').gsub(')', '\\)')
  end
end
