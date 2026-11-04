# frozen_string_literal: true

module Candidate
  class FindMarketApplication < ApplicationInteractor
    delegate :siret, :email, :market_application_id, :invitation_token, to: :context

    def call
      return call_from_invitation if invitation_token.present?

      application = find_application
      return fail_no_application unless application
      return if validate_grouping_member_email(application.grouping_member) == :failed

      context.market_application = application
      application.grouping_member.present? ? handle_existing_grouping_member(application) : handle_reconnection(application)
    end

    private

    def handle_existing_grouping_member(application)
      context.reconnection = application.user_id.present?
    end

    def call_from_invitation
      grouping_member = find_invited_grouping_member
      return fail_no_application(:invitation_not_found) unless grouping_member
      return if validate_grouping_member_email(grouping_member) == :failed

      result = Candidate::SetUpGroupingMemberApplication.call(grouping_member:)
      return context.fail!(errors: result.errors) if result.failure?

      context.market_application = result.market_application
      context.reconnection = false
    end

    def find_invited_grouping_member
      grouping_member = GroupingMember.find_by(invitation_token:)
      return if grouping_member.nil? || grouping_member.invitation_expired?

      grouping_member
    end

    def fail_no_application(error_key = market_application_id.present? ? :no_application_found : :no_market_context)
      context.fail!(errors: { base: [I18n.t("candidate.request_magic_link.#{error_key}")] })
    end

    def validate_grouping_member_email(grouping_member)
      return if grouping_member.blank? || grouping_member.email.blank?
      return if grouping_member.email.casecmp(email).zero?

      context.fail!(errors: { email: [I18n.t('candidate.request_magic_link.reconnection_email_mismatch')] })
      :failed
    end

    def handle_reconnection(application)
      existing_application = find_existing_application_for_reconnection(application)
      context.reconnection = existing_application.present?
      return unless context.reconnection

      context.market_application = existing_application
      validate_email_for_user(existing_application.user)
      context.user = existing_application.user
    end

    def find_existing_application_for_reconnection(application)
      return application if application.user_id.present?

      linked_applications = MarketApplication
        .where(siret:, public_market: application.public_market)
        .where.not(user_id: nil)

      linked_applications.where.not(completed_at: nil).order(completed_at: :desc).first ||
        linked_applications.order(updated_at: :desc).first
    end

    def validate_email_for_user(existing_user)
      return if existing_user.email.casecmp(email).zero?

      context.fail!(errors: { email: [I18n.t('candidate.request_magic_link.reconnection_email_mismatch')] })
    end

    def find_application
      MarketApplication.find_by(identifier: market_application_id, siret:)
    end
  end
end
