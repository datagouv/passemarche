# frozen_string_literal: true

module Candidate
  class LotSelectionsController < Candidate::ApplicationController
    prepend_before_action :find_market_application
    before_action :check_application_not_completed
    before_action :redirect_if_no_lots, only: [:show]

    def show; end

    def update
      policy = LotSelectionPolicy.new(@market_application, lot_ids_param)

      unless policy.valid?
        @errors = policy.errors.map(&:message)
        render :show, status: :unprocessable_content
        return
      end

      @market_application.lot_ids = lot_ids_param
      redirect_to step_candidate_market_application_path(@market_application.identifier, :summary)
    end

    private

    def find_market_application
      @market_application = MarketApplication
        .includes(public_market: :lots)
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
  end
end
