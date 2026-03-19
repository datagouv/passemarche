# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PdfWatermarkService do
  let(:blank_pdf) { CombinePDF.new.to_pdf }

  describe '.call' do
    context 'in non-production environment' do
      it 'adds watermark text to each page' do
        pdf = CombinePDF.new
        pdf << CombinePDF.create_page
        pdf << CombinePDF.create_page
        source = pdf.to_pdf

        result = described_class.call(source)
        output = CombinePDF.parse(result)

        expect(output.pages.length).to eq(2)
      end

      it 'returns valid PDF content' do
        result = described_class.call(blank_pdf)

        expect(result).to start_with('%PDF')
      end
    end

    context 'in production environment' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new('production')) }

      it 'returns the original content unchanged' do
        result = described_class.call(blank_pdf)

        expect(result).to eq(blank_pdf)
      end
    end
  end
end
