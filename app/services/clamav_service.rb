# frozen_string_literal: true

class ClamavService
  class ScanError < StandardError; end

  def self.enabled?
    Rails.application.credentials.dig(:clamav, :enabled) == true
  end

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
  rescue Clamby::VirusDetected
    raise ScanError, "Malware détecté dans #{filename}"
  rescue ScanError
    raise
  rescue StandardError => e
    Rails.logger.error("ClamAV error for #{filename}: #{e.message}")
    nil
  end

  private

  def enabled?
    self.class.enabled?
  end
end
