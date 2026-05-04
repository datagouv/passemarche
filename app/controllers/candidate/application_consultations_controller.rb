# frozen_string_literal: true

module Candidate
  class ApplicationConsultationsController < Candidate::ApplicationController
    prepend_before_action :find_market_application
    before_action :require_completed_application

    def show
      @presenter = MarketApplicationPresenter.new(@market_application)
    end

    private

    def find_market_application
      @market_application = MarketApplication.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      redirect_to candidate_dashboard_path, alert: t('candidate.application_consultations.not_found')
    end

    def require_completed_application
      return if @market_application&.completed_at?

      redirect_to candidate_dashboard_path, alert: t('candidate.application_consultations.not_accessible')
    end
  end
end
