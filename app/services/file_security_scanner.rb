class FileSecurityScanner
  MAX_FILE_SIZE = 50.megabytes
  ALLOWED_EXTENSIONS = %w[pdf doc docx txt xls xlsx csv jpg jpeg png zip].freeze

  class SecurityError < StandardError; end

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

    {
      scanned_at: Time.current.iso8601,
      scan_safe: true,
      scanner: virus_scan_result[:scanner]
    }
  end

  private

  def validate_file_size!
    size = file_size
    return unless size > MAX_FILE_SIZE

    size_mb = (size / 1.megabyte.to_f).round(2)
    max_mb = MAX_FILE_SIZE / 1.megabyte
    raise SecurityError, "Fichier trop volumineux (#{size_mb}MB). Maximum: #{max_mb}MB"
  end

  def validate_extension!
    extension = File.extname(@filename).downcase.delete('.')

    return if ALLOWED_EXTENSIONS.include?(extension)

    raise SecurityError, "Format non autorisé (.#{extension}). Formats acceptés: #{ALLOWED_EXTENSIONS.join(', ')}"
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
    Rails.env.production? || ENV['ENABLE_CLAMAV'] == 'true'
  end
end
