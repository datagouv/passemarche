# frozen_string_literal: true

module FieldConstants
  # Market types used across multiple models
  MARKET_TYPES = %w[supplies services works].freeze
  
  # Field types for form field configuration
  FIELD_TYPES = %w[document_upload text_field checkbox_field].freeze
  
  # Source types for field data sources
  SOURCE_TYPES = %w[authentic_source honor_declaration].freeze
end