# frozen_string_literal: true

class Admin::SubcategoriesController < Admin::ApplicationController
  def reorder
    ordered_ids = params.expect(ordered_ids: [])

    Subcategory.transaction do
      ordered_ids.each_with_index do |id, index|
        Subcategory.where(id:).update_all(position: index) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    head :ok
  end
end
