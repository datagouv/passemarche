# frozen_string_literal: true

class Admin::CategoriesController < Admin::ApplicationController
  def index
    @categories = Category.active.ordered
    @subcategories = Subcategory.active.ordered.includes(:category)
  end

  def reorder
    ordered_ids = params.expect(ordered_ids: [])

    Category.transaction do
      ordered_ids.each_with_index do |id, index|
        Category.where(id:).update_all(position: index) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    head :ok
  end
end
