# frozen_string_literal: true

class SubcategoryUpdateService < ApplicationServiceObject
  def initialize(subcategory:, params:)
    super()
    @subcategory = subcategory
    @params = params
  end

  def perform
    @subcategory.assign_attributes(@params)

    unless @subcategory.save
      @subcategory.errors.each do |error|
        add_error(error.attribute, error.message)
      end
      return
    end

    @result = @subcategory
  end
end
