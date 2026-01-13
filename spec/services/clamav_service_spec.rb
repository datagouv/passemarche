# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClamavService do
  let(:file_path) { Rails.root.join('spec/fixtures/files/test.txt') }
  let(:filename) { 'test.txt' }

  before do
    FileUtils.mkdir_p(Rails.root.join('spec/fixtures/files'))
    File.write(file_path, 'Safe test content')
  end

  after do
    FileUtils.rm_f(file_path)
  end

  describe '.available?' do
    context 'when ClamAV is enabled and installed' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('ENABLE_CLAMAV').and_return('true')
        allow(Clamby).to receive(:scanner_exists?).and_return(true)
      end

      it 'returns true' do
        expect(described_class.available?).to be true
      end
    end

    context 'when ClamAV is disabled' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('ENABLE_CLAMAV').and_return(nil)
        allow(Rails.env).to receive(:production?).and_return(false)
      end

      it 'returns false' do
        expect(described_class.available?).to be false
      end
    end

    context 'when scanner_exists? raises error' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('ENABLE_CLAMAV').and_return('true')
        allow(Clamby).to receive(:scanner_exists?).and_raise(StandardError, 'Connection error')
      end

      it 'returns false' do
        expect(described_class.available?).to be false
      end
    end
  end

  describe '.scan!' do
    context 'when file is safe' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('ENABLE_CLAMAV').and_return('true')
        allow(Clamby).to receive(:scanner_exists?).and_return(true)
        allow(Clamby).to receive(:safe?).and_return(true)
      end

      it 'returns success result with clamav scanner' do
        result = described_class.scan!(file_path.to_s, filename:)

        expect(result).to eq({ scanner: 'clamav' })
      end

      it 'logs scanning activity' do
        expect(Rails.logger).to receive(:info).with(/Scanning with ClamAV/)
        expect(Rails.logger).to receive(:info).with(/Clamby.safe\? returned/)
        expect(Rails.logger).to receive(:info).with(/Scan antivirus OK/)

        described_class.scan!(file_path.to_s, filename:)
      end
    end

    context 'when malware is detected' do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('ENABLE_CLAMAV').and_return('true')
        allow(Clamby).to receive(:scanner_exists?).and_return(true)
        allow(Clamby).to receive(:safe?).and_return(false)
      end

      it 'raises ScanError' do
        expect do
          described_class.scan!(file_path.to_s, filename:)
        end.to raise_error(ClamavService::ScanError, /Malware détecté/)
      end

      it 'logs virus detection' do
        allow(Rails.logger).to receive(:info)
        expect(Rails.logger).to receive(:error).with('⚠️ VIRUS DETECTED!')

        begin
          described_class.scan!(file_path.to_s, filename:)
        rescue ClamavService::ScanError
          # Expected error
        end
      end
    end
  end
end
