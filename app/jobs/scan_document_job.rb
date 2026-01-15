class ScanDocumentJob < ApplicationJob
  queue_as :default

  def perform(blob_id)
    blob = ActiveStorage::Blob.find(blob_id)
    scan_and_update_blob(blob)
  end

  private

  def scan_and_update_blob(blob)
    blob.open { |file| perform_scan(blob, file) }
    blob.save!
  rescue FileSecurityScanner::SecurityError => e
    handle_malware_detection(blob, e)
  end

  def perform_scan(blob, file)
    scan_result = FileSecurityScanner.scan!(file.path, filename: blob.filename.to_s)
    blob.metadata.merge!(scan_result)
  end

  def handle_malware_detection(blob, error)
    Rails.logger.error "🦠 Malware détecté: #{error.message}"

    # Store malware info in metadata
    # The file remains attached but marked as unsafe for display purposes
    blob.metadata.merge!(
      scanned_at: Time.current.iso8601,
      scan_safe: false,
      scanner: 'clamav',
      scan_error: error.message
    )
    blob.save!
  end
end
