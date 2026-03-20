# frozen_string_literal: true

class Admin::SubcategoriesController < Admin::ApplicationController
  before_action :require_admin_role!, only: %i[new create edit update reorder]

  def new
    @subcategory = Subcategory.new
    @categories = Category.active.ordered
  end

  def edit
    @subcategory = Subcategory.find(params[:id])
    @categories = Category.active.ordered
  end

  def create
    @subcategory = Subcategory.new(subcategory_params)
    @subcategory.key = @subcategory.buyer_label.parameterize(separator: '_') if @subcategory.buyer_label.present?

    if @subcategory.save
      redirect_to admin_categories_path, notice: t('.success')
    else
      @categories = Category.active.ordered
      render turbo_stream: turbo_stream.replace('modal', template: 'admin/subcategories/new', layout: false),
        status: :unprocessable_content
    end
  end

  def update
    @subcategory = Subcategory.find(params[:id])

    if @subcategory.update(subcategory_params)
      redirect_to admin_categories_path, notice: t('.success')
    else
      @categories = Category.active.ordered
      render turbo_stream: turbo_stream.replace('modal', template: 'admin/subcategories/edit', layout: false),
        status: :unprocessable_content
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
