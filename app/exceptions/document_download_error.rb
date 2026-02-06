# frozen_string_literal: true

class DocumentDownloadError < ApplicationError
  attr_reader :url, :http_status, :content_type

  def initialize(message, url: nil, http_status: nil, content_type: nil, context: {})
    @url = url
    @http_status = http_status
    @content_type = content_type
    super(message, context: context.merge(url:, http_status:, content_type:).compact)
  end
end
