# frozen_string_literal: true

module Buyer
  class PublicMarketsController < ApplicationController
    include Wicked::Wizard

    steps :configure, :required_fields, :additional_fields, :summary

    before_action :find_public_market

    def show
      case step
      when :required_fields
        @required_fields = @public_market.fields_by_category_and_subcategory(@public_market.effective_required_fields)
      when :additional_fields
        @optional_fields = @public_market.fields_by_category_and_subcategory(@public_market.effective_optional_fields)
      end

      render_wizard
    end

    def update
      case step
      when :configure
        handle_configure_step
      when :required_fields
        jump_to(:additional_fields)
      when :additional_fields
        handle_additional_fields_step
      when :summary
        @public_market.mark_form_configuration_completed!
        @public_market.complete!
        redirect_to finish_wizard_path, notice: t('buyer.public_markets.wizard_completed')
      end

      render_wizard @public_market
    end

    private

    def handle_configure_step
      return unless @public_market.defense_industry.nil? && params[:public_market].present?

      defense_value = params[:public_market][:defense_industry] == 'true'
      @public_market.update!(defense_industry: defense_value)
    end

    def handle_additional_fields_step
      selected_fields = params[:selected_optional_fields] || []
      @public_market.update!(selected_optional_fields: selected_fields)
      jump_to(:summary)
    end

    def configure_params
      params.expect(public_market: [:defense_industry])
    end

    def find_public_market
      @public_market = PublicMarket.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: 'Le marché recherché n\'a pas été trouvé', status: :not_found
    end

    def finish_wizard_path
      root_path
    end
  end
end
