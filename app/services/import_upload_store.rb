# frozen_string_literal: true

class ImportUploadStore
  STALE_AFTER = 1.hour
  UUID_PATTERN = /\A[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}\z/

  def persist(uploaded_file)
    token = SecureRandom.uuid
    FileUtils.mkdir_p(dir)
    FileUtils.cp(uploaded_file.tempfile.path, path_for(token))
    token
  end

  def path_for(token)
    validate_token!(token)
    dir.join("#{token}.csv").to_s
  end

  def exists?(token)
    File.exist?(path_for(token))
  end

  def delete(token)
    FileUtils.rm_f(path_for(token))
  end

  def cleanup_stale
    return unless dir.exist?

    dir.each_child do |file|
      FileUtils.rm_f(file) if file.mtime < STALE_AFTER.ago
    end
  end

  private

  def dir
    Pathname.new(Rails.configuration.import_upload_dir)
  end

  def validate_token!(token)
    raise ArgumentError, 'Invalid import token' unless token.match?(UUID_PATTERN)
  end
end
