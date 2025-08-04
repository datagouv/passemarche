# frozen_string_literal: true

module Buyer
  class PublicMarketsController < ApplicationController
    include Wicked::Wizard

    steps :configure, :required_fields, :additional_fields, :summary

    before_action :find_public_market
    before_action :initialize_presenter

    def show
      case step
      when :required_fields
        @required_fields = @presenter.available_required_fields_by_category_and_subcategory
      when :additional_fields
        @optional_fields = @presenter.available_optional_fields_by_category_and_subcategory
      end

      render_wizard
    end

    def update
      case step
      when :configure
        handle_configure_step
      when :required_fields
        handle_required_fields_step
      when :additional_fields
        handle_additional_fields_step
      when :summary
        @public_market.complete!
        redirect_to finish_wizard_path, notice: t('buyer.public_markets.wizard_completed')
      end

      render_wizard @public_market
    end

    private

    def handle_configure_step
      return if params[:public_market].blank?

      return unless params[:public_market][:add_defense_market_type] == 'true'

      return if @public_market.market_type_codes.include?('defense')

      @public_market.market_type_codes << 'defense'
      @public_market.save!
    end

    def handle_required_fields_step
      @public_market.market_attributes = @presenter.available_required_market_attributes
      @public_market.save!

      jump_to(:additional_fields)
    end

    def handle_additional_fields_step
      selected_attribute_keys = params[:selected_attribute_keys] || []
      selected_optional_attributes = MarketAttribute.where(key: selected_attribute_keys)

      existing_required_attributes = @public_market.market_attributes.required

      all_attributes = (existing_required_attributes + selected_optional_attributes).uniq

      @public_market.market_attributes = all_attributes
      @public_market.save!
      jump_to(:summary)
    end

    def find_public_market
      @public_market = PublicMarket.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: 'Le marché recherché n\'a pas été trouvé', status: :not_found
    end

    def initialize_presenter
      @presenter = PublicMarketPresenter.new(@public_market)
    end

    def finish_wizard_path
      root_path
    end
  end
end
