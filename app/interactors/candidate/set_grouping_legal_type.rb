# frozen_string_literal: true

module Candidate
  class SetGroupingLegalType < ApplicationInteractor
    delegate :market_application, :legal_type, to: :context

    def call
      context.grouping = find_grouping
      return fail_with(:grouping, :grouping_not_found) unless context.grouping
      return fail_with(:legal_type, :legal_type_locked) if context.grouping.composition_confirmed?
      return fail_with(:legal_type, :legal_type_invalid) unless valid_legal_type?

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

    def fail_with(attribute, message_key)
      context.fail!(errors: { attribute => [I18n.t("candidate.validations.#{message_key}")] })
    end

    def errors_from(record)
      record.errors.each_with_object({}) do |error, hash|
        (hash[error.attribute] ||= []) << error.message
      end
    end
  end
end
