# frozen_string_literal: true

class CategoryExportService < ApplicationServiceObject
  def perform
    @result = build_export_data
  end

  private

  def build_export_data
    {
      'categories' => Category.active.ordered.map { |category| export_category(category) }
    }
  end

  def export_category(category)
    {
      'key' => category.key,
      'position' => category.position,
      'buyer_label' => category.buyer_label,
      'candidate_label' => category.candidate_label,
      'subcategories' => category.subcategories.active.ordered.map { |sub| export_subcategory(sub) }
    }
  end

  def export_subcategory(subcategory)
    {
      'key' => subcategory.key,
      'position' => subcategory.position,
      'buyer_label' => subcategory.buyer_label,
      'candidate_label' => subcategory.candidate_label
    }
  end
end
