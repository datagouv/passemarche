# frozen_string_literal: true

module Candidate
  class MarketApplicationsController < ApplicationController
    include Wicked::Wizard

    steps :company_identification,
      :market_and_company_information,
      :exclusion_criteria,
      :economic_capacities,
      :technical_capacities,
      :summary

    before_action :find_market_application
    before_action :check_application_not_completed, except: [:retry_sync]
    before_action :set_wizard_steps

    def show
      @presenter = MarketApplicationPresenter.new(@market_application) if step == :summary

      render_wizard
    end

    def update
      if step == :summary
        handle_summary_completion
      elsif step == :company_identification
        handle_company_identification
      elsif @market_application.update(market_application_params)
        render_wizard(@market_application)
      else
        render_wizard
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
      # company_identification doesn't count as a step
      @wizard_steps = steps - [:company_identification]
    end

    def handle_company_identification
      if @market_application.update(market_application_params) && @market_application.market_attribute_responses.none?
        @market_application.public_market.market_attributes.find_each do |market_attribute|
          MarketAttributeResponse.create!(
            market_application: @market_application,
            market_attribute:,
            type: market_attribute.input_type.camelize
          )
        end
      end

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
      @market_application = MarketApplication.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: 'La candidature recherchée n\'a pas été trouvée', status: :not_found
    end

    def check_application_not_completed
      return unless @market_application.completed?

      redirect_to candidate_sync_status_path(@market_application.identifier),
        alert: t('candidate.market_applications.market_application_completed_cannot_edit')
    end

    def market_application_params
      params.fetch(:market_application, {}).permit(:siret)
    end

    def finish_wizard_path
      root_path
    end
  end
end
