# frozen_string_literal: true

class Admin::CategoriesController < Admin::ApplicationController
  def index
    @categories = Category.active.ordered
    @subcategories = Subcategory.active.ordered.includes(:category)
  end

  def edit
    @category = Category.find(params[:id])
  end

  def update
    @category = Category.find(params[:id])
    service = CategoryUpdateService.new(
      category: @category,
      params: category_params
    )
    service.perform

    if service.success?
      redirect_to admin_categories_path, notice: t('.success')
    else
      render :edit, status: :unprocessable_content
    end
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

  private

  def category_params
    params.expect(category: %i[buyer_label candidate_label])
  end
end
