# frozen_string_literal: true

class BugTrackerService
  class << self
    def capture_exception(exception, context = {})
      Sentry.capture_exception(exception, extra: context)
      log_exception_details(exception, context)
      log_exception_metadata(exception)
    end

    private

    def log_exception_details(exception, context)
      Rails.logger.error "[BUG_TRACKER] Exception: #{exception.class} - #{exception.message}"
      Rails.logger.error "[BUG_TRACKER] Context: #{context.to_json}"
      return unless exception.respond_to?(:backtrace) && exception.backtrace

      Rails.logger.error "[BUG_TRACKER] Backtrace:\n#{exception.backtrace.first(10).join("\n")}"
    end

    def log_exception_metadata(exception)
      Rails.logger.error "[BUG_TRACKER] HTTP Status: #{exception.http_status}" if exception.respond_to?(:http_status)
      return unless exception.respond_to?(:response_body)

      Rails.logger.error "[BUG_TRACKER] Response Body: #{exception.response_body}"
    end

    public

    def capture_message(message, level: :error, context: {})
      Sentry.capture_message(message, level:, extra: context)
      Rails.logger.public_send(level, "[BUG_TRACKER] #{message}")
      Rails.logger.public_send(level, "[BUG_TRACKER] Context: #{context.to_json}") if context.any?
    end
  end
end
