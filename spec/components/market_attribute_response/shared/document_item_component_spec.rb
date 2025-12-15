# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MarketAttributeResponse::Shared::DocumentItemComponent, type: :component do
  let(:market_application) { create(:market_application) }
  let(:document) { create_document('test_document.pdf', 1024) }
  let(:naming_service) { instance_double(DocumentNamingService) }

  before do
    allow(DocumentNamingService).to receive(:new).with(market_application).and_return(naming_service)
    allow(naming_service).to receive(:original_filename_for).with(document).and_return('original_name.pdf')
    allow(naming_service).to receive(:system_filename_for).with(document).and_return('SYS_001_document.pdf')
  end

  describe '#display_name' do
    context 'with web context' do
      it 'returns the original filename' do
        component = described_class.new(document:, market_application:, context: :web)

        expect(component.display_name).to eq('original_name.pdf')
      end
    end

    context 'with pdf context' do
      it 'returns the original filename' do
        component = described_class.new(document:, market_application:, context: :pdf)

        expect(component.display_name).to eq('original_name.pdf')
      end
    end

    context 'with buyer context' do
      it 'returns the system filename' do
        component = described_class.new(document:, market_application:, context: :buyer)

        expect(component.display_name).to eq('SYS_001_document.pdf')
      end
    end
  end

  describe 'rendering' do
    it 'renders the file icon' do
      component = described_class.new(document:, market_application:)

      render_inline(component)

      expect(page).to have_css('span.fr-icon-file-fill')
    end

    it 'renders the display name' do
      component = described_class.new(document:, market_application:)

      render_inline(component)

      expect(page).to have_text('original_name.pdf')
    end

    context 'with show_size: true' do
      it 'renders the file size' do
        component = described_class.new(document:, market_application:, show_size: true)

        render_inline(component)

        expect(page).to have_text('1 KB')
      end
    end

    context 'with show_size: false' do
      it 'does not render the file size' do
        component = described_class.new(document:, market_application:, show_size: false)

        render_inline(component)

        expect(page).not_to have_text('1 KB')
      end
    end
  end

  private

  def create_document(filename, byte_size)
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new('x' * byte_size),
      filename:,
      content_type: 'application/pdf'
    )
  end
end
