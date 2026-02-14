# frozen_string_literal: true

class Admin::SubcategoriesController < Admin::ApplicationController
  def edit
    @subcategory = Subcategory.find(params[:id])
    @categories = Category.active.ordered
  end

  def update
    @subcategory = Subcategory.find(params[:id])
    service = SubcategoryUpdateService.new(
      subcategory: @subcategory,
      buyer_params: subcategory_buyer_params,
      candidate_params: subcategory_candidate_params
    )
    service.perform

    if service.success?
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

  def subcategory_buyer_params
    params.expect(subcategory: %i[buyer_label buyer_category_id])
      .then { |p| { label: p[:buyer_label], category_id: p[:buyer_category_id] } }
  end

  def subcategory_candidate_params
    params.expect(subcategory: %i[candidate_label candidate_category_id])
      .then { |p| { label: p[:candidate_label], category_id: p[:candidate_category_id] } }
  end
end
