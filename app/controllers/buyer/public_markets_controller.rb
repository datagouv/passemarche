# frozen_string_literal: true

module Buyer
  class PublicMarketsController < ApplicationController
    include Wicked::Wizard

    steps :configure, :required_documents, :optional_documents, :summary

    before_action :find_public_market

    def show
      render_wizard
    end

    def update
      case step
      when :configure
        handle_configure_step
      when :required_documents
        # Handle required documents (future implementation)
        jump_to(:optional_documents)
      when :optional_documents
        # Handle optional documents form submission (future implementation)
        jump_to(:summary)
      when :summary
        # Handle finalization (future implementation)
        @public_market.complete!
        redirect_to finish_wizard_path, notice: t('buyer.public_markets.wizard_completed')
      end

      render_wizard @public_market
    end

    private

    def handle_configure_step
      return unless @public_market.defense.nil? && params[:public_market].present?

      defense_value = params[:public_market][:defense] == 'true'
      @public_market.update!(defense: defense_value)
    end

    def configure_params
      params.expect(public_market: [:defense])
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
