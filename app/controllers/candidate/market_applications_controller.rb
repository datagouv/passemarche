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
    before_action :check_application_not_completed
    before_action :set_wizard_steps

    def show
      render_wizard
    end

    def update
      if step == :summary
        @market_application.complete!

        MarketApplicationWebhookJob.perform_later(@market_application.id)

        redirect_to candidate_sync_status_path(@market_application.identifier)
      elsif @market_application.update(market_application_params)
        render_wizard(@market_application)
      else
        render_wizard
      end
    end

    def retry_sync
      @market_application.update!(sync_status: :sync_pending)

      MarketApplicationWebhookJob.perform_later(@market_application.id)

      redirect_to candidate_sync_status_path(@market_application.identifier),
        notice: t('candidate.market_application.sync_retry_initiated')
    end

    private

    def set_wizard_steps
      # company_identification doesn't count as a step
      @wizard_steps = steps - [:company_identification]
    end

    def find_market_application
      @market_application = MarketApplication.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: 'La candidature recherchée n\'a pas été trouvée', status: :not_found
    end

    def check_application_not_completed
      # Placeholder for future implementation
      # Will prevent editing completed applications
    end

    def market_application_params
      params.fetch(:market_application, {}).permit(:siret)
    end

    def finish_wizard_path
      root_path
    end
  end
end
