class ScanDocumentJob < ApplicationJob
  queue_as :default
  discard_on ActiveRecord::RecordNotFound

  def perform(blob_id)
    blob = ActiveStorage::Blob.find(blob_id)
    scan_and_update_blob(blob)
  end

  private

  def scan_and_update_blob(blob)
    blob.open { |file| perform_scan(blob, file) }
    blob.save!
  rescue FileSecurityScanner::SecurityError => e
    handle_scan_error(blob, e)
  end

  def perform_scan(blob, file)
    scan_result = FileSecurityScanner.scan!(file.path, filename: blob.filename.to_s)
    blob.metadata.merge!(scan_result)
  end

  def handle_scan_error(blob, error)
    if malware_error?(error)
      mark_as_malware(blob, error)
    else
      mark_as_scan_failed(blob, error)
    end

    blob.save!
  end

  def malware_error?(error)
    error.message.match?(/malware|virus/i)
  end

  def mark_as_malware(blob, error)
    blob.metadata.merge!(
      scanned_at: Time.current.iso8601,
      scan_safe: false,
      scanner: 'clamav',
      scan_error: error.message
    )
  end

  def mark_as_scan_failed(blob, error)
    blob.metadata.merge!(
      scanned_at: Time.current.iso8601,
      scanner: 'error',
      scan_error: error.message
    )
  end
end
