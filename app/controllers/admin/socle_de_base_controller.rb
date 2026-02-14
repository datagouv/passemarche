# frozen_string_literal: true

class Admin::SocleDeBaseController < Admin::ApplicationController
  def index
    service = MarketAttributeQueryService.new(filters: filter_params)
    service.perform
    @market_attributes = service.result
    @stats = SocleDeBaseStatsService.call
    @categories = Category.active.ordered
    @market_types = MarketType.active
  end

  def show
    load_market_attribute
    @presenter = SocleDeBasePresenter.new(@market_attribute)
  end

  def edit
    load_market_attribute
    load_form_data
  end

  def update
    load_market_attribute
    service = MarketAttributeUpdateService.new(
      market_attribute: @market_attribute,
      params: market_attribute_params
    )
    service.perform

    if service.success?
      redirect_to admin_socle_de_base_path(@market_attribute), notice: t('.success')
    else
      load_form_data
      render :edit, status: :unprocessable_content
    end
  end

  def archive
    load_market_attribute
    @market_attribute.update!(deleted_at: Time.current)
    redirect_to admin_socle_de_base_index_path, notice: t('.success')
  end

  private

  def load_market_attribute
    @market_attribute = MarketAttribute.includes(:market_types, :subcategory).find(params[:id])
  end

  def load_form_data
    @categories = Category.active.ordered
    @subcategories = Subcategory.active.ordered.includes(:category)
    @market_types = MarketType.active
    @input_types = MarketAttribute.input_types.keys
  end

  def filter_params
    params.permit(:query, :category, :source, :market_type_id).to_h.symbolize_keys
  end

  def market_attribute_params
    params.expect(market_attribute: [
      :input_type, :mandatory, :subcategory_id, :category_key, :subcategory_key,
      :buyer_name, :buyer_description, :candidate_name, :candidate_description,
      :api_name, :api_key,
      { market_type_ids: [] }
    ])
  end
end
