# frozen_string_literal: true

class AntivirusService
  class ScanError < StandardError; end

  def self.scan!(file_path, filename:)
    new(file_path, filename:).scan!
  end

  def initialize(file_path, filename:)
    @file_path = file_path
    @filename = filename
  end

  def scan!
    scanner_services.each do |service|
      result = try_service(service)
      return result if result
    end

    handle_all_scanners_failed
  end

  private

  def scanner_services
    [
      ClamavService
    ]
  end

  def try_service(service)
    return nil unless service.available?

    service.scan!(@file_path, filename: @filename)
  rescue ClamavService::ScanError => e
    raise ScanError, e.message
  rescue StandardError => e
    Rails.logger.error("#{service.name} error: #{e.message}")
    nil
  end

  def handle_all_scanners_failed
    raise ScanError, 'Service antivirus indisponible' if Rails.env.production?

    Rails.logger.warn("⚠️ No antivirus available in #{Rails.env}, skipping scan")
    { scanner: 'none' }
  end
end
