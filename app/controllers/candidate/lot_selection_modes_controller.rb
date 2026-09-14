# frozen_string_literal: true

module Candidate
  class LotSelectionModesController < Candidate::ApplicationController
    include Candidate::GroupementFeatureGuard
    include Candidate::MarketApplicationGuard
    include Candidate::MandataireGroupingGuard

    before_action :redirect_if_no_lots, only: [:show]

    def show
      @presenter = Candidate::LotSelectionModePresenter.new(@market_application)
    end

    def update
      result = Candidate::SetLotSelectionModes.call(market_application: @market_application, lot_modes: lot_modes_param)

      return handle_success if result.success?

      @presenter = Candidate::LotSelectionModePresenter.new(@market_application)
      @errors = result.errors
      render :show, status: :unprocessable_content
    end

    private

    def lot_modes_param
      params.fetch(:lot_modes, {}).permit!.to_h
    end

    def redirect_if_no_lots
      return if @market_application.public_market.lots.any?

      redirect_to grouping_legal_type_candidate_market_application_path(@market_application.identifier)
    end

    def handle_success
      redirect_to grouping_legal_type_candidate_market_application_path(@market_application.identifier)
    end
  end
end
