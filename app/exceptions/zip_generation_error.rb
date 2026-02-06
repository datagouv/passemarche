# frozen_string_literal: true

class ZipGenerationError < ApplicationError
  attr_reader :stage, :document_id, :filename

  def initialize(message, stage: nil, document_id: nil, filename: nil, context: {})
    @stage = stage
    @document_id = document_id
    @filename = filename
    super(message, context: context.merge(stage:, document_id:, filename:).compact)
  end
end
