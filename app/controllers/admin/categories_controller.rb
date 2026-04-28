# frozen_string_literal: true

class Admin::CategoriesController < Admin::ApplicationController
  before_action :require_admin_role!, only: %i[new create edit update reorder]

  def index
    @categories = Category.active.ordered
    @subcategories = Subcategory.active.ordered.includes(:category)
  end

  def new
    @category = Category.new
  end

  def edit
    @category = Category.find(params[:id])
  end

  def create
    @category = Category.new(category_params)
    @category.key = @category.buyer_label.parameterize(separator: '_') if @category.buyer_label.present?

    if @category.save
      redirect_to admin_categories_path, notice: t('.success')
    else
      render turbo_stream: turbo_stream.replace('modal', template: 'admin/categories/new', layout: false),
        status: :unprocessable_content
    end
  end

  def update
    @category = Category.find(params[:id])

    if @category.update(category_params)
      redirect_to admin_categories_path, notice: t('.success')
    else
      render turbo_stream: turbo_stream.replace('modal', template: 'admin/categories/edit', layout: false),
        status: :unprocessable_content
    end
  end

  def reorder
    ordered_ids = params.expect(ordered_ids: [])

    Category.transaction do
      ordered_ids.each_with_index do |id, index|
        Category.active.where(id:).update_all(position: index) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    head :ok
  end

  private

  def category_params
    params.expect(category: %i[buyer_label candidate_label])
  end
end
