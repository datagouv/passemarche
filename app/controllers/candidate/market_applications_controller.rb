# frozen_string_literal: true

module Candidate
  class MarketApplicationsController < ApplicationController
    include Wicked::Wizard

    prepend_before_action :set_steps
    before_action :check_application_not_completed, except: [:retry_sync]
    before_action :set_wizard_steps

    def show
      @presenter = MarketApplicationPresenter.new(@market_application)

      if custom_view_exists?
        render_wizard
      else
        render 'generic_step', locals: { step: }
      end
    end

    def update
      @presenter = MarketApplicationPresenter.new(@market_application)

      if step == :summary
        handle_summary_completion
      elsif step == :company_identification
        handle_company_identification
      elsif @market_application.update(market_application_params)
        @market_application.market_attribute_responses.reload
        render_wizard(@market_application)
      elsif custom_view_exists?
        render_wizard
      else
        render 'generic_step', locals: { step: }
      end
    end

    def retry_sync
      @market_application.update!(sync_status: :sync_pending)

      MarketApplicationWebhookJob.perform_later(
        @market_application.id,
        request_host: request.host_with_port,
        request_protocol: request.protocol
      )

      redirect_to candidate_sync_status_path(@market_application.identifier),
        notice: t('candidate.market_application.sync_retry_initiated')
    end

    private

    def set_wizard_steps
      find_market_application
      return unless @market_application

      category_keys = @market_application.public_market.market_attributes
        .order(:id)
        .pluck(:category_key)
        .compact
        .uniq

      @wizard_steps = category_keys.map(&:to_sym) + [:summary]
    end

    def set_steps
      find_market_application
      return unless @market_application

      subcategory_keys = @market_application.public_market.market_attributes
        .order(:id)
        .pluck(:subcategory_key)
        .compact
        .uniq

      self.steps = (%i[company_identification market_information] + subcategory_keys.map(&:to_sym) + [:summary]).uniq
    end

    def handle_company_identification
      @market_application.update(market_application_params)

      render_wizard(@market_application)
    end

    def handle_summary_completion
      result = CompleteMarketApplication.call(market_application: @market_application)

      if result.success?
        queue_webhook_and_redirect
      else
        display_completion_error(result.message)
      end
    rescue StandardError => e
      log_and_display_error(e)
    end

    def queue_webhook_and_redirect
      MarketApplicationWebhookJob.perform_later(
        @market_application.id,
        request_host: request.host_with_port,
        request_protocol: request.protocol
      )
      redirect_to candidate_sync_status_path(@market_application.identifier)
    end

    def display_completion_error(message)
      flash.now[:alert] = message
      render_wizard
    end

    def log_and_display_error(error)
      Rails.logger.error "Error completing market application #{@market_application.identifier}: #{error.message}"
      flash.now[:alert] = t('candidate.market_applications.completion_error')
      render_wizard
    end

    def find_market_application
      @market_application = MarketApplication
        .includes(
          public_market: :market_attributes,
          market_attribute_responses: :market_attribute
        )
        .find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      @market_application = nil
      render plain: 'La candidature recherchée n\'a pas été trouvée', status: :not_found
    end

    def check_application_not_completed
      return unless @market_application.completed?

      redirect_to candidate_sync_status_path(@market_application.identifier),
        alert: t('candidate.market_applications.market_application_completed_cannot_edit')
    end

    def custom_view_exists?
      lookup_context.exists?(step.to_s, 'candidate/market_applications', false)
    end

    def market_application_params
      params.fetch(:market_application, {}).permit(
        :siret,
        market_attribute_responses_attributes: [
          :id,
          :market_attribute_id,
          :type,
          :_destroy,
          :text,
          :checked,
          :file,
          { files: [] },
          { value: {} },
          :year_1_turnover, :year_1_market_percentage, :year_1_fiscal_year_end,
          :year_2_turnover, :year_2_market_percentage, :year_2_fiscal_year_end,
          :year_3_turnover, :year_3_market_percentage, :year_3_fiscal_year_end
        ]
      )
    end

    def finish_wizard_path
      root_path
    end
  end
end
