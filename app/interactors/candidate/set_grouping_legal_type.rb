# frozen_string_literal: true

module Candidate
  class SetGroupingLegalType < ApplicationInteractor
    delegate :market_application, :legal_type, to: :context

    def call
      context.grouping = find_grouping
      return fail_grouping_not_found unless context.grouping
      return fail_legal_type_invalid unless valid_legal_type?

      update_legal_type
    end

    private

    def update_legal_type
      return if context.grouping.update(legal_type:)

      context.fail!(errors: errors_from(context.grouping))
    end

    def find_grouping
      Grouping.joins(:mandataire_market_application).find_by(market_applications: { id: market_application.id })
    end

    def valid_legal_type?
      legal_type.to_s.in?(Grouping.legal_types.keys)
    end

    def fail_grouping_not_found
      context.fail!(errors: { grouping: [I18n.t('candidate.validations.grouping_not_found')] })
    end

    def fail_legal_type_invalid
      context.fail!(errors: { legal_type: [I18n.t('candidate.validations.legal_type_invalid')] })
    end

    def errors_from(record)
      record.errors.each_with_object({}) do |error, hash|
        (hash[error.attribute] ||= []) << error.message
      end
    end
  end
end
