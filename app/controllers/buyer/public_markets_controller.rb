# frozen_string_literal: true

module Buyer
  class PublicMarketsController < ApplicationController
    include Wicked::Wizard

    steps :setup, :required_fields, :additional_fields, :summary

    before_action :find_public_market
    before_action :check_market_not_completed, except: [:retry_sync]
    before_action :initialize_presenter, except: [:retry_sync]

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
      result = MarketConfigurationService.call(@public_market, step, step_params)

      if step == :summary
        redirect_to buyer_sync_status_path(@public_market.identifier)
      else
        jump_to(result[:next_step]) if result.is_a?(Hash) && result[:next_step]
        render_wizard @public_market
      end
    end

    def retry_sync
      @public_market.update!(sync_status: :sync_pending)

      WebhookSyncJob.perform_later(@public_market.id)

      redirect_to buyer_sync_status_path(@public_market.identifier),
        notice: t('buyer.public_markets.sync_retry_initiated')
    end

    private

    def step_params
      case step
      when :setup, :summary
        params[:public_market] || {}
      when :additional_fields
        { selected_attribute_keys: params[:selected_attribute_keys] || [] }
      else
        {}
      end
    end

    def find_public_market
      @public_market = PublicMarket.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: 'Le marché recherché n\'a pas été trouvé', status: :not_found
    end

    def check_market_not_completed
      return unless @public_market.completed?

      redirect_to buyer_sync_status_path(@public_market.identifier),
        alert: t('buyer.public_markets.market_completed_cannot_edit')
    end

    def initialize_presenter
      @presenter = PublicMarketPresenter.new(@public_market)
    end

    def finish_wizard_path
      root_path
    end
  end
end
