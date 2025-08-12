# frozen_string_literal: true

module Candidate
  class MarketApplicationsController < ApplicationController
    include Wicked::Wizard

    steps :company_identification

    before_action :find_market_application
    before_action :check_application_not_completed

    def show
      render_wizard
    end

    def update
      case step
      when :company_identification
        if @market_application.update(market_application_params)
          redirect_to finish_wizard_path
        else
          render_wizard
        end
      end
    end

    private

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
