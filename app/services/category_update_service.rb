# frozen_string_literal: true

class CategoryUpdateService < ApplicationServiceObject
  def initialize(category:, params:)
    super()
    @category = category
    @params = params
  end

  def perform
    @category.assign_attributes(@params)

    unless @category.save
      @category.errors.each do |error|
        add_error(error.attribute, error.message)
      end
      return
    end

    @result = @category
  end
end
