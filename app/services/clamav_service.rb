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
    Rails.logger.info("🔍 Scanning with ClamAV: #{file_path}")
    is_safe = ::Clamby.safe?(file_path)
    Rails.logger.info("🔍 Clamby.safe? returned: #{is_safe}")

    unless is_safe
      Rails.logger.error('⚠️ VIRUS DETECTED!')
      raise ScanError, "Malware détecté dans #{filename}"
    end

    Rails.logger.info("✓ Scan antivirus OK: #{filename}")
    { scanner: 'clamav' }
  end

  private

  def enabled?
    Rails.env.production? || ENV['ENABLE_CLAMAV'] == 'true'
  end
end
