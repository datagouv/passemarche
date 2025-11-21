# frozen_string_literal: true

require 'ostruct'

class PublicMarketCreationService < ApplicationServiceObject
  def initialize(editor, params)
    super()
    @editor = editor
    @params = params
  end

  def perform
    validate_editor
    return self if failure?

    create_public_market
    self
  end

  private

  attr_reader :editor, :params

  def validate_editor
    return if editor

    add_error(:editor, 'Editor not found')
  end

  def create_public_market
    market = editor.public_markets.build(market_params)

    if market.save
      @result = market
    else
      market.errors.each do |error|
        add_error(error.attribute, error.message)
      end
    end
  end

  def market_params
    params.slice(:name, :lot_name, :deadline, :siret, :market_type_codes)
  end
end
