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

      handle_step_update
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

    def handle_step_update
      if step.to_sym == :summary
        handle_summary_completion
      elsif step.to_sym == :company_identification
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

    def set_wizard_steps
      find_market_application
      return unless @market_application

      @presenter = MarketApplicationPresenter.new(@market_application)
      @wizard_steps = @presenter.stepper_steps
    end

    def set_steps
      find_market_application
      return unless @market_application

      @presenter ||= MarketApplicationPresenter.new(@market_application)
      self.steps = @presenter.wizard_steps
    end

    def handle_company_identification
      if @market_application.update(market_application_params)
        populate_insee_data
        populate_rne_data
      end

      render_wizard(@market_application)
    end

    def populate_insee_data
      return if @market_application.siret.blank?

      result = Insee.call(
        params: { siret: @market_application.siret },
        market_application: @market_application
      )

      return if result.success?

      # Mark INSEE attributes as needing manual input after API failure
      mark_api_attributes_as_manual_after_failure('Insee')

      flash.now[:alert] = t('candidate.market_applications.insee_api_error',
        error: result.error)
    end

    def populate_rne_data
      return if @market_application.siret.blank?

      result = Rne.call(
        params: { siret: @market_application.siret },
        market_application: @market_application
      )

      return if result.success?

      # Mark RNE attributes as needing manual input after API failure
      mark_api_attributes_as_manual_after_failure('rne')

      flash.now[:alert] = t('candidate.market_applications.rne_api_error',
        error: result.error)
    end

    def mark_api_attributes_as_manual_after_failure(api_name)
      # Find all attributes from this API for this market
      api_attributes = @market_application.public_market.market_attributes
        .where(api_name:)

      # Mark responses as manual_after_api_failure so candidate can fill them
      api_attributes.each do |attribute|
        response = @market_application.market_attribute_responses
          .find_or_initialize_by(market_attribute: attribute)

        # Only mark as manual_after_api_failure if not already set
        next if response.manual_after_api_failure?

        response.source = :manual_after_api_failure
        response.save! if response.persisted? || response.changed?
      end
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
        market_attribute_responses_attributes: {}
      )
    end

    def finish_wizard_path
      root_path
    end
  end
end
