class FileSecurityScanner
  class SecurityError < StandardError; end

  def self.max_file_size
    Rails.configuration.file_upload.max_size
  end

  def self.allowed_extensions
    Rails.configuration.file_upload.allowed_extensions
  end

  def self.scan!(file_path, filename:)
    new(file_path, filename:).scan!
  end

  def initialize(file_path_or_io, filename:)
    @file_path_or_io = file_path_or_io
    @filename = filename
  end

  def scan!
    validate_file_size!
    validate_extension!
    virus_scan_result = scan_for_virus! || { scanner: 'none' }

    result = {
      scanned_at: Time.current.iso8601,
      scanner: virus_scan_result[:scanner]
    }

    # Only mark as safe if actually scanned
    result[:scan_safe] = true if virus_scan_result[:scanner] != 'none'

    result
  end

  private

  def validate_file_size!
    size = file_size
    max_size = self.class.max_file_size
    return unless size > max_size

    size_mb = (size / 1.megabyte.to_f).round(2)
    max_mb = max_size / 1.megabyte
    raise SecurityError, "Fichier trop volumineux (#{size_mb}MB). Maximum: #{max_mb}MB"
  end

  def validate_extension!
    extension = File.extname(@filename).downcase.delete('.')
    allowed = self.class.allowed_extensions

    return if allowed.include?(extension)

    raise SecurityError, "Format non autorisé (.#{extension}). Formats acceptés: #{allowed.join(', ')}"
  end

  def scan_for_virus!
    return { scanner: 'none' } unless antivirus_enabled?

    result = with_temp_file do |temp_path|
      AntivirusService.scan!(temp_path, filename: @filename)
    end
    result || { scanner: 'none' }
  rescue AntivirusService::ScanError => e
    raise SecurityError, e.message
  end

  def with_temp_file(&)
    if file_path?
      yield @file_path_or_io
    else
      create_temp_file_from_io(&)
    end
  end

  def file_path?
    @file_path_or_io.is_a?(String) && File.exist?(@file_path_or_io)
  end

  def create_temp_file_from_io
    Tempfile.create(['scan', File.extname(@filename)]) do |temp_file|
      temp_file.binmode
      temp_file.write(read_content)
      temp_file.flush
      temp_file.close
      rewind_io
      yield temp_file.path
    end
  end

  def read_content
    if @file_path_or_io.respond_to?(:read)
      @file_path_or_io.read
    else
      @file_path_or_io.to_s
    end
  end

  def rewind_io
    @file_path_or_io.rewind if @file_path_or_io.respond_to?(:rewind)
  end

  def file_size
    if @file_path_or_io.is_a?(String) && File.exist?(@file_path_or_io)
      File.size(@file_path_or_io)
    elsif @file_path_or_io.respond_to?(:size)
      @file_path_or_io.size
    elsif @file_path_or_io.respond_to?(:bytesize)
      @file_path_or_io.bytesize
    else
      0
    end
  end

  def antivirus_enabled?
    ClamavService.available?
  end
end
