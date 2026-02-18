# frozen_string_literal: true

class Admin::SubcategoriesController < Admin::ApplicationController
  def edit
    @subcategory = Subcategory.find(params[:id])
    @categories = Category.active.ordered
  end

  def update
    @subcategory = Subcategory.find(params[:id])

    if @subcategory.update(subcategory_params)
      redirect_to admin_categories_path, notice: t('.success')
    else
      @categories = Category.active.ordered
      render :edit, status: :unprocessable_content
    end
  end

  def reorder
    ordered_ids = params.expect(ordered_ids: [])

    Subcategory.transaction do
      ordered_ids.each_with_index do |id, index|
        Subcategory.active.where(id:).update_all(position: index) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    head :ok
  end

  private

  def subcategory_params
    params.expect(subcategory: %i[buyer_label candidate_label category_id])
  end
end
