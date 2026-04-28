# frozen_string_literal: true

module Candidate
  class LotSelectionsController < Candidate::ApplicationController
    include Candidate::MarketApplicationGuard

    prepend_before_action :find_market_application
    before_action :redirect_if_no_lots, only: [:show]

    def show
      @presenter = MarketApplicationPresenter.new(@market_application)
    end

    def update
      policy = LotSelectionPolicy.new(@market_application, lot_ids_param)

      unless policy.valid?
        render_lot_selection_error(policy.errors.map(&:message))
        return
      end

      @market_application.lot_ids = lot_ids_param

      if params[:final_submit].present?
        complete_application
      else
        redirect_to step_candidate_market_application_path(@market_application.identifier, :api_data_recovery_status)
      end
    end

    private

    def find_market_application
      @market_application = MarketApplication
        .includes(:lots, public_market: :lots)
        .find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: "La candidature recherchée n'a pas été trouvée", status: :not_found
    end

    def redirect_if_no_lots
      return if @market_application.public_market.lots.any?

      redirect_to step_candidate_market_application_path(@market_application.identifier, :api_data_recovery_status)
    end

    def lot_ids_param
      params.fetch(:market_application, {}).permit(lot_ids: [])[:lot_ids]&.map(&:to_i)&.reject(&:zero?) || []
    end

    def render_lot_selection_error(errors)
      @errors = errors
      @presenter = MarketApplicationPresenter.new(@market_application)
      render :show, status: :unprocessable_content
    end

    def complete_application
      result = MarketApplicationStepUpdateService.call(
        @market_application, :summary, {},
        request_host: request.host_with_port,
        request_protocol: request.protocol
      )

      return render_submission_error(result[:flash_messages]) unless result[:success]

      redirect_to candidate_sync_status_path(@market_application.identifier)
    end

    def render_submission_error(flash_messages)
      flash_messages.each { |key, value| flash.now[key] = value }
      render_lot_selection_error(flash_messages.values.compact)
    end
  end
end
