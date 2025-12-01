# frozen_string_literal: true

module Buyer
  class PublicMarketsController < ApplicationController
    include Wicked::Wizard

    prepend_before_action :set_dynamic_steps, except: [:retry_sync]
    prepend_before_action :initialize_presenter, except: [:retry_sync]
    prepend_before_action :find_public_market
    before_action :check_market_not_completed, except: [:retry_sync]
    before_action :set_wizard_steps

    def show
      case step
      when :setup, :summary
        render_wizard
      else
        # Dynamic category step
        @current_category = step.to_s
        @required_fields = @presenter.required_fields_for_category(@current_category)
        @optional_fields = @presenter.optional_fields_for_category(@current_category)
        @has_optional_fields = @presenter.optional_fields_for_category?(@current_category)
        render_wizard nil, template: step_template
      end
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

      PublicMarketWebhookJob.perform_later(@public_market.id)

      redirect_to buyer_sync_status_path(@public_market.identifier),
        notice: t('buyer.public_markets.sync_retry_initiated')
    end

    private

    def set_dynamic_steps
      self.steps = @presenter.wizard_steps
    end

    def set_wizard_steps
      @wizard_steps = @presenter.stepper_steps
    end

    def step_params
      case step
      when :setup, :summary
        params[:public_market] || {}
      else
        # Category step - collect selected optional fields
        { selected_attribute_keys: params[:selected_attribute_keys] || [] }
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

    def step_template
      step_specific_template = "buyer/public_markets/#{step}"
      if template_exists?(step_specific_template)
        step_specific_template
      else
        'buyer/public_markets/generic_step'
      end
    end
  end
end
