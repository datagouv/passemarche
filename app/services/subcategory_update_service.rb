# frozen_string_literal: true

class SubcategoryUpdateService < ApplicationServiceObject
  def initialize(subcategory:, buyer_params:, candidate_params:)
    super()
    @subcategory = subcategory
    @buyer_params = buyer_params
    @candidate_params = candidate_params
  end

  def perform
    Subcategory.transaction do
      @subcategory.assign_attributes(
        buyer_label: @buyer_params[:label],
        buyer_category_id: @buyer_params[:category_id],
        candidate_label: @candidate_params[:label],
        candidate_category_id: @candidate_params[:category_id]
      )

      unless @subcategory.save
        @subcategory.errors.each do |error|
          add_error(error.attribute, error.message)
        end
        raise ActiveRecord::Rollback
      end

      @result = @subcategory
    end
  end
end
