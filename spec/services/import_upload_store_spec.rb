# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImportUploadStore do
  subject(:store) { described_class.new }

  let(:upload_dir) { Pathname.new(Rails.configuration.import_upload_dir) }

  after do
    FileUtils.rm_rf(upload_dir)
  end

  describe '#persist' do
    let(:uploaded_file) do
      tempfile = Tempfile.new(['test', '.csv'])
      tempfile.write('header1;header2')
      tempfile.rewind
      ActionDispatch::Http::UploadedFile.new(tempfile:, filename: 'test.csv')
    end

    it 'returns a UUID token' do
      token = store.persist(uploaded_file)
      expect(token).to match(/\A[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}\z/)
    end

    it 'copies the file to the upload directory' do
      token = store.persist(uploaded_file)
      expect(File).to exist(upload_dir.join("#{token}.csv"))
    end
  end

  describe '#path_for' do
    let(:valid_token) { SecureRandom.uuid }

    it 'returns the file path for a valid UUID' do
      expect(store.path_for(valid_token)).to eq(upload_dir.join("#{valid_token}.csv").to_s)
    end

    it 'raises ArgumentError for a token with path traversal' do
      expect { store.path_for('../../etc/passwd') }.to raise_error(ArgumentError, /Invalid import token/)
    end

    it 'raises ArgumentError for an arbitrary string' do
      expect { store.path_for('not-a-uuid') }.to raise_error(ArgumentError, /Invalid import token/)
    end

    it 'raises ArgumentError for an empty string' do
      expect { store.path_for('') }.to raise_error(ArgumentError, /Invalid import token/)
    end
  end

  describe '#exists?' do
    it 'returns true when the file exists' do
      FileUtils.mkdir_p(upload_dir)
      token = SecureRandom.uuid
      FileUtils.touch(upload_dir.join("#{token}.csv"))

      expect(store.exists?(token)).to be true
    end

    it 'returns false when the file does not exist' do
      expect(store.exists?(SecureRandom.uuid)).to be false
    end
  end

  describe '#delete' do
    it 'removes the file' do
      FileUtils.mkdir_p(upload_dir)
      token = SecureRandom.uuid
      path = upload_dir.join("#{token}.csv")
      FileUtils.touch(path)

      store.delete(token)
      expect(File).not_to exist(path)
    end
  end

  describe '#cleanup_stale' do
    before { FileUtils.mkdir_p(upload_dir) }

    it 'removes files older than 1 hour' do
      old_file = upload_dir.join('old.csv')
      FileUtils.touch(old_file, mtime: 2.hours.ago.to_time)

      store.cleanup_stale
      expect(File).not_to exist(old_file)
    end

    it 'keeps recent files' do
      recent_file = upload_dir.join('recent.csv')
      FileUtils.touch(recent_file)

      store.cleanup_stale
      expect(File).to exist(recent_file)
    end

    it 'does nothing when directory does not exist' do
      FileUtils.rm_rf(upload_dir)
      expect { store.cleanup_stale }.not_to raise_error
    end
  end
end
