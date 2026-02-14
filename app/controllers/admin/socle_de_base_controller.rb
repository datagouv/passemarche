# frozen_string_literal: true

class Admin::SocleDeBaseController < Admin::ApplicationController
  before_action :load_form_data, only: %i[new create]

  def index
    @market_attributes = MarketAttribute.active.ordered.includes(:market_types)
    @stats = SocleDeBaseStatsService.call
  end

  def new
    @market_attribute = MarketAttribute.new
  end

  def create
    service = MarketAttributeCreationService.new(params: market_attribute_params)
    service.perform

    if service.success?
      redirect_to admin_socle_de_base_index_path, notice: t('.success')
    else
      @market_attribute = service.result || MarketAttribute.new
      @errors = service.errors
      render :new, status: :unprocessable_content
    end
  end

  private

  def market_attribute_params
    params.expect(market_attribute: [
      :input_type, :mandatory, :source,
      :category_key, :subcategory_key,
      :api_name, :api_key,
      :buyer_name, :candidate_name,
      :buyer_description, :candidate_description,
      { market_type_ids: [] }
    ])
  end

  def load_form_data
    @categories = Category.active.ordered
    @subcategories = Subcategory.active.ordered.includes(:category)
    @market_types = MarketType.active
    @input_types = MarketAttribute.input_types.keys
  end
end
