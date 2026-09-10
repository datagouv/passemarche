# frozen_string_literal: true

module Candidate
  class GroupingCompositionsController < Candidate::ApplicationController
    include Candidate::GroupementFeatureGuard
    include Candidate::MarketApplicationGuard
    include Candidate::WizardRoutable

    prepend_before_action :find_market_application
    before_action :redirect_unless_mandataire
    before_action :redirect_unless_legal_type_set

    def show
      enqueue_pending_company_name_resolutions
      @grouping = grouping
      @grouping_member = GroupingMember.new

      respond_to do |format|
        format.html
        format.json do
          set_no_cache_headers
          render json: { company_names_pending: company_names_pending? }
        end
      end
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

    def redirect_unless_legal_type_set
      return if grouping.legal_type.present?

      redirect_to grouping_legal_type_candidate_market_application_path(@market_application.identifier)
    end

    def enqueue_pending_company_name_resolutions
      grouping.grouping_members.where(company_name: nil).find_each do |member|
        ResolveGroupingMemberCompanyNameJob.perform_later(member.id)
      end
    end

    def company_names_pending?
      grouping.grouping_members.exists?(company_name: nil)
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
