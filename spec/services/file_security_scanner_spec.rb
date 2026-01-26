# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FileSecurityScanner do
  let(:file) { Tempfile.new(['test', '.txt']) }
  let(:filename) { 'test.txt' }

  before do
    file.write('Safe test content')
    file.rewind
  end

  after do
    file.close
    file.unlink
  end

  describe '.scan!' do
    context 'with valid file and successful antivirus scan' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('ENABLE_CLAMAV').and_return('true')
        allow(AntivirusService).to receive(:scan!).and_return({ scanner: 'clamav' })
      end

      it 'returns complete metadata' do
        result = described_class.scan!(file.path, filename:)

        expect(result).to include(:scanned_at, :scan_safe, :scanner)
        expect(result[:scan_safe]).to be true
        expect(result[:scanner]).to eq('clamav')
      end

      it 'calls AntivirusService' do
        expect(AntivirusService).to receive(:scan!).and_call_original
        allow(Clamby).to receive(:scanner_exists?).and_return(true)
        allow(Clamby).to receive(:safe?).and_return(true)

        described_class.scan!(file.path, filename:)
      end
    end

    context 'when file is too large' do
      before do
        allow_any_instance_of(described_class).to receive(:file_size)
          .and_return(FileSecurityScanner::MAX_FILE_SIZE + 1)
      end

      it 'raises SecurityError' do
        expect do
          described_class.scan!(file.path, filename:)
        end.to raise_error(FileSecurityScanner::SecurityError, /trop volumineux/)
      end
    end

    context 'when file extension is not allowed' do
      let(:filename) { 'test.exe' }

      it 'raises SecurityError' do
        expect do
          described_class.scan!(file.path, filename:)
        end.to raise_error(FileSecurityScanner::SecurityError, /Format non autorisé/)
      end
    end

    context 'when antivirus detects malware' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('ENABLE_CLAMAV').and_return('true')
        allow(Clamby).to receive(:scanner_exists?).and_return(true)
        allow(Clamby).to receive(:safe?).and_return(false)
      end

      it 'raises SecurityError' do
        expect do
          described_class.scan!(file.path, filename:)
        end.to raise_error(FileSecurityScanner::SecurityError, /Malware détecté/)
      end
    end

    context 'with IO object instead of path' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('ENABLE_CLAMAV').and_return('true')
        allow(AntivirusService).to receive(:scan!).and_return({ scanner: 'clamav' })
      end

      it 'creates temp file and scans it' do
        io = StringIO.new('test content')

        result = described_class.scan!(io, filename:)

        expect(result[:scan_safe]).to be true
      end
    end
  end
end
