# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AntivirusService do
  let(:file_path) { Rails.root.join('spec/fixtures/files/test.txt') }
  let(:filename) { 'test.txt' }

  before do
    FileUtils.mkdir_p(Rails.root.join('spec/fixtures/files'))
    File.write(file_path, 'Safe test content')
  end

  after do
    FileUtils.rm_f(file_path)
  end

  describe '.scan!' do
    context 'when ClamavService is available and scan succeeds' do
      before do
        allow(ClamavService).to receive(:available?).and_return(true)
        allow(ClamavService).to receive(:scan!).and_return({ scanner: 'clamav' })
      end

      it 'returns scan result from ClamavService' do
        result = described_class.scan!(file_path.to_s, filename:)

        expect(result).to eq({ scanner: 'clamav' })
      end

      it 'calls ClamavService.scan!' do
        expect(ClamavService).to receive(:scan!).with(file_path.to_s, filename:)

        described_class.scan!(file_path.to_s, filename:)
      end
    end

    context 'when ClamavService detects malware' do
      before do
        allow(ClamavService).to receive(:available?).and_return(true)
        allow(ClamavService).to receive(:scan!)
          .and_raise(ClamavService::ScanError, 'Malware détecté dans test.txt')
      end

      it 'raises AntivirusService::ScanError' do
        expect do
          described_class.scan!(file_path.to_s, filename:)
        end.to raise_error(AntivirusService::ScanError, /Malware détecté/)
      end
    end

    context 'when no scanner is available' do
      before do
        allow(ClamavService).to receive(:available?).and_return(false)
      end

      context 'in production' do
        before do
          allow(Rails.env).to receive(:production?).and_return(true)
        end

        it 'raises ScanError' do
          expect do
            described_class.scan!(file_path.to_s, filename:)
          end.to raise_error(AntivirusService::ScanError, 'Service antivirus indisponible')
        end
      end

      context 'in development' do
        before do
          allow(Rails.env).to receive(:production?).and_return(false)
        end

        it 'returns none scanner and logs warning' do
          allow(Rails.logger).to receive(:warn).with(/failed, trying fallback/)
          expect(Rails.logger).to receive(:warn).with(/No antivirus available/)

          result = described_class.scan!(file_path.to_s, filename:)

          expect(result).to eq({ scanner: 'none' })
        end
      end
    end

    context 'when ClamavService fails with error' do
      before do
        allow(ClamavService).to receive(:available?).and_return(true)
        allow(ClamavService).to receive(:scan!)
          .and_raise(StandardError, 'Connection timeout')
        allow(Rails.env).to receive(:production?).and_return(false)
      end

      it 'logs error and tries fallback' do
        expect(Rails.logger).to receive(:error).with(/ClamavService error/)
        expect(Rails.logger).to receive(:warn).with(/failed, trying fallback/)
        expect(Rails.logger).to receive(:warn).with(/No antivirus available/)

        result = described_class.scan!(file_path.to_s, filename:)

        expect(result).to eq({ scanner: 'none' })
      end
    end
  end
end
