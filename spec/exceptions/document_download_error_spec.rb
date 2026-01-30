# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DocumentDownloadError do
  it 'inherits from ApplicationError' do
    expect(described_class).to be < ApplicationError
  end

  describe '#initialize' do
    it 'accepts url, http_status and content_type' do
      error = described_class.new(
        'Download failed',
        url: 'https://example.com/doc.pdf',
        http_status: 404,
        content_type: 'text/html'
      )

      expect(error.message).to eq('Download failed')
      expect(error.url).to eq('https://example.com/doc.pdf')
      expect(error.http_status).to eq(404)
      expect(error.content_type).to eq('text/html')
    end

    it 'includes attributes in context' do
      error = described_class.new('Failed', url: 'http://test.com', http_status: 500)

      expect(error.context).to include(url: 'http://test.com', http_status: 500)
    end
  end
end
