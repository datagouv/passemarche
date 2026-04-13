# frozen_string_literal: true

module Candidate
  class LotSelectionsController < Candidate::ApplicationController
    prepend_before_action :find_market_application
    before_action :check_application_not_completed
    before_action :redirect_if_no_lots, only: [:show]

    def show
      @submission_intent = submission_intent
      @presenter = MarketApplicationPresenter.new(@market_application)
    end

    def update
      policy = LotSelectionPolicy.new(@market_application, lot_ids_param)

      unless policy.valid?
        render_show_with_errors(policy.errors.map(&:message))
        return
      end

      @market_application.lot_ids = lot_ids_param

      return complete_submission if submission_intent == 'submit'

      redirect_to_summary
    end

    private

    def find_market_application
      @market_application = MarketApplication
        .includes(:lots, public_market: :lots)
        .find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: "La candidature recherchée n'a pas été trouvée", status: :not_found
    end

    def check_application_not_completed
      return unless @market_application.completed?

      redirect_to candidate_sync_status_path(@market_application.identifier),
        alert: t('candidate.market_applications.market_application_completed_cannot_edit')
    end

    def redirect_if_no_lots
      return if @market_application.public_market.lots.any?

      redirect_to step_candidate_market_application_path(@market_application.identifier, :company_identification)
    end

    def lot_ids_param
      params.fetch(:market_application, {}).permit(lot_ids: [])[:lot_ids] || []
    end

    def submission_intent
      params[:submission_intent].to_s
    end

    def queue_webhook_and_redirect(flash_options = {})
      MarketApplicationWebhookJob.perform_later(
        @market_application.id,
        request_host: request.host_with_port,
        request_protocol: request.protocol
      )
      redirect_to candidate_sync_status_path(@market_application.identifier), flash_options
    end

    def complete_submission
      complete_result = MarketApplicationStepUpdateService.call(@market_application, :summary, {})
      apply_flash_messages(complete_result)

      return queue_webhook_and_redirect if complete_result[:success] && complete_result[:redirect] == :sync_status
      return redirect_to_summary if complete_result[:success]

      render_show_with_errors
    end

    def apply_flash_messages(result)
      result[:flash_messages].each do |key, value|
        flash.now[key] = value
      end
    end

    def redirect_to_summary
      redirect_to step_candidate_market_application_path(@market_application.identifier, :summary)
    end

    def render_show_with_errors(errors = nil)
      @errors = errors
      @submission_intent = submission_intent
      @presenter = MarketApplicationPresenter.new(@market_application)
      render :show, status: :unprocessable_content
    end
  end
end
