# frozen_string_literal: true

module Candidate
  class MarketApplicationsController < ApplicationController
    include Wicked::Wizard

    prepend_before_action :set_steps
    before_action :check_application_not_completed, except: [:retry_sync]
    before_action :set_wizard_steps

    def show
      @presenter = MarketApplicationPresenter.new(@market_application)
      @api_block_status_presenter = ApiBlockStatusPresenter.new(@market_application) if step == :api_data_recovery_status

      respond_to do |format|
        format.html { render_html_step }
        format.json { render_json_step }
      end
    end

    def update
      @presenter = MarketApplicationPresenter.new(@market_application)

      result = MarketApplicationStepUpdateService.call(
        @market_application,
        step.to_sym,
        market_application_params
      )

      handle_service_result(result)
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

    def handle_service_result(result)
      # Apply flash messages from service
      result[:flash_messages].each do |key, value|
        flash.now[key] = value
      end

      if result[:redirect] == :sync_status
        queue_webhook_and_redirect
      elsif result[:success]
        render_wizard(@market_application)
      elsif custom_view_exists?
        render_wizard(nil, status: :unprocessable_entity)
      else
        render 'generic_step', locals: { step: }, status: :unprocessable_entity
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

    def queue_webhook_and_redirect
      MarketApplicationWebhookJob.perform_later(
        @market_application.id,
        request_host: request.host_with_port,
        request_protocol: request.protocol
      )
      redirect_to candidate_sync_status_path(@market_application.identifier)
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
      permitted_params = params.fetch(:market_application, {}).permit(
        :siret,
        :attests_no_exclusion_motifs
      )

      permitted_params[:market_attribute_responses_attributes] = permitted_nested_attributes if params[:market_application] && params[:market_application][:market_attribute_responses_attributes]

      permitted_params
    end

    def permitted_nested_attributes
      nested_params = params.dig(:market_application, :market_attribute_responses_attributes)
      return {} unless nested_params

      # Validation is handled at the model level
      nested_params.permit!
    end

    def finish_wizard_path
      root_path
    end

    def set_no_cache_headers
      response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
      response.headers['Pragma'] = 'no-cache'
      response.headers['Expires'] = '0'
    end

    def api_fetch_status_response
      { api_fetch_status: @market_application.api_fetch_status }
    end

    def render_html_step
      if custom_view_exists?
        render_wizard
      else
        render 'generic_step', locals: { step: }
      end
    end

    def render_json_step
      if step == :api_data_recovery_status
        set_no_cache_headers
        render json: api_fetch_status_response
      else
        head :not_found
      end
    end
  end
end
