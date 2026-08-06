# frozen_string_literal: true

module Candidate
  class AddGroupingMember < ApplicationInteractor
    delegate :grouping, :siret, :email, to: :context

    def call
      validate_siret
      validate_email
      create_member
    end

    private

    def validate_siret
      return fail_siret_blank if siret.blank?
      return fail_siret_invalid unless SiretValidator.valid?(siret)
      return fail_siret_same_as_mandataire if siret == mandataire_siret

      fail_siret_already_added if grouping.grouping_members.exists?(siret:)
    end

    def mandataire_siret
      grouping.mandataire_grouping_member&.siret
    end

    def validate_email
      return fail_email_blank if email.blank?

      fail_email_invalid unless EmailValidator.valid?(email)
    end

    def create_member
      member = grouping.grouping_members.new(role: :co_traitant, siret:, email:, company_name: fetch_company_name)
      return context.grouping_member = member if member.save

      context.fail!(errors: errors_from(member))
    end

    def fetch_company_name
      result = FetchRaisonSociale.call(siret:)
      result.raison_sociale if result.success?
    rescue StandardError => e
      Sentry.capture_exception(e)
      nil
    end

    def fail_siret_blank
      context.fail!(errors: { siret: [I18n.t('candidate.validations.siret_blank')] })
    end

    def fail_siret_invalid
      context.fail!(errors: { siret: [I18n.t('candidate.validations.siret_invalid')] })
    end

    def fail_siret_same_as_mandataire
      context.fail!(errors: { siret: [I18n.t('candidate.validations.siret_same_as_mandataire')] })
    end

    def fail_siret_already_added
      context.fail!(errors: { siret: [I18n.t('candidate.validations.siret_already_added')] })
    end

    def fail_email_blank
      context.fail!(errors: { email: [I18n.t('candidate.validations.email_blank')] })
    end

    def fail_email_invalid
      context.fail!(errors: { email: [I18n.t('candidate.validations.email_invalid')] })
    end

    def errors_from(record)
      record.errors.each_with_object({}) do |error, hash|
        (hash[error.attribute] ||= []) << error.message
      end
    end
  end
end
