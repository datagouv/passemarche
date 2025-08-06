# frozen_string_literal: true

class PublicMarketCreationService < ApplicationService
  def initialize(editor, params)
    @editor = editor
    @params = params
  end

  def call
    validate_editor!
    create_public_market!
  end

  private

  attr_reader :editor, :params

  def validate_editor!
    raise ActiveRecord::RecordNotFound, 'Editor not found' unless editor
  end

  def create_public_market!
    editor.public_markets.create!(market_params)
  end

  def market_params
    params.slice(:name, :lot_name, :deadline, :market_type_codes)
  end
end
