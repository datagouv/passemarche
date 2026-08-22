# frozen_string_literal: true

module Candidate
  class GroupingCompositionsController < Candidate::ApplicationController
    include Candidate::GroupementFeatureGuard
    include Candidate::MarketApplicationGuard
    include Candidate::WizardRoutable

    prepend_before_action :find_market_application
    before_action :redirect_unless_mandataire

    def show
      resolve_mandataire_company_name
      @grouping = grouping
      @grouping_member = GroupingMember.new
    end

    def create_member
      result = Candidate::AddGroupingMember.call(grouping:, siret: params[:siret], email: params[:email])
      assign_create_member_result(result)

      render turbo_stream: member_form_turbo_streams, status: result.success? ? :ok : :unprocessable_content
    end

    def destroy_member
      Candidate::RemoveGroupingMember.call(grouping:, grouping_member_id: params[:id])

      render turbo_stream: [
        turbo_stream.replace(
          'grouping_members_table',
          partial: 'candidate/grouping_compositions/members_table',
          locals: { grouping:, market_application: @market_application, editable: true }
        ),
        turbo_stream.replace(
          'grouping_composition_actions',
          partial: 'candidate/grouping_compositions/composition_actions',
          locals: { grouping: }
        )
      ]
    end

    private

    def find_market_application
      @market_application = MarketApplication.find_by!(identifier: params[:identifier])
    rescue ActiveRecord::RecordNotFound
      render plain: "La candidature recherchée n'a pas été trouvée", status: :not_found
    end

    def redirect_unless_mandataire
      return if grouping

      redirect_to application_mode_candidate_market_application_path(@market_application.identifier)
    end

    def resolve_mandataire_company_name
      mandataire_member = grouping.grouping_members.mandataire.first
      return if mandataire_member.nil? || mandataire_member.company_name.present?

      result = FetchRaisonSociale.call(siret: mandataire_member.siret)
      mandataire_member.update(company_name: result.raison_sociale) if result.success?
    end

    def assign_create_member_result(result)
      if result.success?
        @grouping_member = GroupingMember.new
      else
        @grouping_member = grouping.grouping_members.new(siret: params[:siret], email: params[:email])
        @errors = result.errors
      end
    end

    def member_form_turbo_streams
      [
        turbo_stream.replace(
          'grouping_members_table',
          partial: 'candidate/grouping_compositions/members_table',
          locals: { grouping:, market_application: @market_application, editable: true }
        ),
        turbo_stream.replace(
          'grouping_member_form',
          partial: 'candidate/grouping_compositions/member_form',
          locals: { grouping:, market_application: @market_application, grouping_member: @grouping_member, errors: @errors }
        ),
        turbo_stream.replace(
          'grouping_composition_actions',
          partial: 'candidate/grouping_compositions/composition_actions',
          locals: { grouping: }
        )
      ]
    end

    def grouping
      return @grouping if defined?(@grouping)

      @grouping = Grouping.joins(:mandataire_market_application).find_by(market_applications: { id: @market_application.id })
    end
  end
end
