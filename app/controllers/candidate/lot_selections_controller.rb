# frozen_string_literal: true

module Candidate
  class LotSelectionsController < Candidate::ApplicationController
    include Candidate::MarketApplicationGuard
    include Candidate::ApplicationModeGuard

    prepend_before_action :find_market_application
    before_action :redirect_if_no_lots, only: [:show]

    def show
      @presenter = MarketApplicationPresenter.new(@market_application)
      @editing = !@presenter.solidaire_co_traitant? && (!@presenter.lots_saved? || params[:edit].present?)
    end

    def update
      return handle_final_submit if params[:final_submit].present?
      return redirect_to_lot_selection if @market_application.solidaire_co_traitant?

      policy = LotSelectionPolicy.new(@market_application, lot_ids_param)

      unless policy.valid?
        render_lot_selection_error(policy.errors.map(&:message))
        return
      end

      update_declared_lots
      redirect_to_lot_selection
    end

    private

    def update_declared_lots
      @market_application.transaction do
        @market_application.lot_ids = lot_ids_param
        @market_application.purge_inapplicable_data!
      end
    end

    def find_market_application
      @market_application = MarketApplication
        .includes(
          { lots: %i[market_type platform_market_type] },
          public_market: { lots: %i[market_type platform_market_type] }
        )
        .find_by!(identifier: params[:identifier])
    end

    def redirect_if_no_lots
      return if @market_application.public_market.lots.any?

      redirect_to step_candidate_market_application_path(@market_application.identifier, :api_data_recovery_status)
    end

    def lot_ids_param
      params.fetch(:market_application, {}).permit(lot_ids: [])[:lot_ids]&.map(&:to_i)&.reject(&:zero?) || []
    end

    def redirect_to_lot_selection
      redirect_to lot_selection_candidate_market_application_path(@market_application.identifier)
    end

    def render_lot_selection_error(errors)
      @errors = errors
      @presenter = MarketApplicationPresenter.new(@market_application)
      @editing = !@presenter.solidaire_co_traitant?
      render :show, status: :unprocessable_content
    end

    def handle_final_submit
      return redirect_to_lot_selection if @market_application.co_traitant_of_grouping?

      complete_application
    end

    def complete_application
      result = MarketApplicationStepUpdateService.call(@market_application, :summary, {})

      return render_submission_error(result[:flash_messages]) unless result[:success]

      redirect_to locked_application_redirect_path
    end

    def render_submission_error(flash_messages)
      flash_messages.each { |key, value| flash.now[key] = value }
      render_lot_selection_error(flash_messages.values.compact)
    end
  end
end
