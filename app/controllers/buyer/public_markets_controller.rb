# frozen_string_literal: true

module Buyer
  class PublicMarketsController < ApplicationController
    # TODO: Implement Wicked wizard integration
    # include Wicked::Wizard
    # steps :configure, :required_documents, :optional_documents, :summary

    before_action :find_public_market

    def show
      return redirect_to_first_step if params[:step].blank?

      render_step_or_redirect
    end

    def update
      case params[:step].to_sym
      when :configure
        handle_configure_step
      when :optional_documents
        # Handle optional documents form submission (future implementation)
        redirect_to buyer_public_market_path(@public_market.identifier, step: :summary)
      when :summary
        # Handle finalization (future implementation)
        redirect_to root_path
      else
        redirect_to buyer_public_market_path(@public_market.identifier, step: :configure)
      end
    end

    private

    def handle_configure_step
      # Only update is_defense if it wasn't set by editor (nil means not provided by editor)
      @public_market.update!(configure_params) if @public_market.is_defense.nil? && params[:public_market].present?

      redirect_to buyer_public_market_path(@public_market.identifier, step: :required_documents)
    end

    def configure_params
      params.expect(public_market: [:defense])
    end

    def find_public_market
      @public_market = PublicMarket.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: 'Le marché recherché n\'a pas été trouvé', status: :not_found
    end

    def redirect_to_first_step
      redirect_to buyer_public_market_path(@public_market.identifier, step: :configure)
    end

    def render_step_or_redirect
      case params[:step].to_sym
      when :configure, :required_documents, :optional_documents, :summary
        render params[:step]
      else
        redirect_to_first_step
      end
    end
  end
end
