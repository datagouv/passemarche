# frozen_string_literal: true

module Candidate
  class MarketApplicationsController < Candidate::ApplicationController
    include Wicked::Wizard
    include Candidate::MarketApplicationGuard

    prepend_before_action :set_steps
    prepend_before_action :find_market_application
    before_action :set_wizard_steps
    skip_before_action :check_application_not_completed, only: %i[retry_sync]

    def show
      if step == :api_data_recovery_status
        @api_block_status_presenter = ApiBlockStatusPresenter.new(@market_application)
        @back_path = back_path_before_wizard
      end

      respond_to do |format|
        format.html { render_html_step }
        format.json { render_json_step }
      end
    end

    def update
      result = MarketApplicationStepUpdateService.call(
        @market_application,
        step.to_sym,
        market_application_params,
        request_host: request.host_with_port,
        request_protocol: request.protocol
      )

      handle_service_result(result)
    end

    def retry_sync
      @market_application.update!(sync_status: :sync_pending)

      queue_webhook_and_redirect(notice: t('candidate.market_application.sync_retry_initiated'))
    end

    private

    def handle_service_result(result)
      # Apply flash messages from service
      result[:flash_messages].each do |key, value|
        flash.now[key] = value
      end

      if result[:redirect] == :sync_status
        redirect_to candidate_sync_status_path(@market_application.identifier)
      elsif result[:success]
        render_wizard(@market_application)
      elsif custom_view_exists?
        render_wizard(nil, status: :unprocessable_entity)
      else
        render 'generic_step', locals: { step: }, status: :unprocessable_content
      end
    end

    def set_wizard_steps
      @wizard_steps = presenter.stepper_steps
    end

    def set_steps
      self.steps = presenter.wizard_steps
    end

    def find_market_application
      @market_application = MarketApplication
        .includes(
          :lots,
          public_market: %i[lots market_attributes],
          market_attribute_responses: :market_attribute
        )
        .find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      @market_application = nil
      render plain: 'La candidature recherchée n\'a pas été trouvée', status: :not_found
    end

    def presenter
      @presenter ||= MarketApplicationPresenter.new(@market_application)
    end

    def custom_view_exists?
      lookup_context.exists?(step.to_s, 'candidate/market_applications', false)
    end

    def market_application_params
      permitted_params = params.fetch(:market_application, {}).permit(
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

    def back_path_before_wizard
      if @market_application.public_market.lots.any?
        lot_selection_candidate_market_application_path(@market_application.identifier)
      else
        company_identification_candidate_market_application_path(@market_application.identifier)
      end
    end

    def finish_wizard_path
      root_path
    end

    def render_html_step
      prefill_blank_email_responses

      if custom_view_exists?
        render_wizard
      else
        render 'generic_step', locals: { step: }
      end
    end

    def prefill_blank_email_responses
      Candidate::PrefillEmailAttributeResponses.call(
        market_application: @market_application,
        candidate_email: current_candidate.email
      )
    end

    def render_json_step
      if step == :api_data_recovery_status
        set_no_cache_headers
        render json: { api_fetch_status: @market_application.api_fetch_status }
      elsif step == :summary
        set_no_cache_headers
        result = Candidate::PrepareDocumentScanStatus.call(market_application: @market_application, view_context:)
        render json: result.scan_status
      else
        head :not_found
      end
    end
  end
end
