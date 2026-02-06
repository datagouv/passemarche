# frozen_string_literal: true

class ClamavService
  class ScanError < StandardError; end

  def self.available?
    new.available?
  end

  def self.scan!(file_path, filename:)
    new.scan!(file_path, filename:)
  end

  def available?
    return false unless enabled?

    ::Clamby.scanner_exists?
  rescue StandardError
    false
  end

  def scan!(file_path, filename:)
    is_safe = ::Clamby.safe?(file_path)

    raise ScanError, "Malware détecté dans #{filename}" unless is_safe

    { scanner: 'clamav' }
  end

  private

  def enabled?
    Rails.env.production? || ENV['ENABLE_CLAMAV'] == 'true'
  end
end
